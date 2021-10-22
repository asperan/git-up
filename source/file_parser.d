module file_parser;

import std.regex;

import repository;
import utility.logging;
import utility.parsing : getFullFilePath, toShortOrdinal;
import configuration;

import asperan.option;
import dyaml;

/**
    Loads Gitfile if it exists.
    Parses options and repository informations.
*/
LocalRepository[] loadRepositoriesFromGitfile(in string filePath) {
  const Node root = loadRootNodeFromFile(filePath);
  parseGlobalOptions(root);
  return parseRepositoryInformations(root);
}

private Node loadRootNodeFromFile(in string filePath) {
  import std.file : exists;
  import std.path : dirSeparator;
  string parsedFilePath = getFullFilePath(filePath == "" ? "." ~ dirSeparator ~ "Gitfile" : filePath);
  if (!exists(parsedFilePath)) { 
    printParsingErrorAndExit("Gitfile '" ~ parsedFilePath ~ "' does not exist.");
  }
  Loader loader = Loader.fromFile(parsedFilePath);
  if (loader.empty()) {
    printParsingErrorAndExit("Gitfile '" ~ parsedFilePath ~ "' is empty.");
  }
  return loader.load();
}

private void parseGlobalOptions(Node root) {
  import std.typecons : tuple;
  if ("GlobalOptions" in root && root["GlobalOptions"].type == NodeType.mapping) {
    printVerbose("Parsing file options...");
    foreach (string key, string value ; root["GlobalOptions"]) {
      parseGitfileOption(tuple!(string, string)(key, value));
    }
  }
}

private LocalRepository[] parseRepositoryInformations(Node root) {
  if ("Repositories" in root && root["Repositories"].type == NodeType.sequence) {
    printVerbose("Parsing repositories...");
    import std.range : zip, iota;
    import std.algorithm.iteration : map;
    import std.array : array;
    return zip(root["Repositories"].sequence, iota(0, root["Repositories"].length))
           .map!(r => buildRepoInfo(r[0], " @ " ~ toShortOrdinal(r[1] + 1) ~ " repository"))
           .array;
  } else {
    return printParsingErrorAndExit("Repositories not specified or empty.");
  }
}

import std.typecons : Tuple, tuple;

private alias RepositoryReference = Tuple!(TreeReferenceType, string, string);

private LocalRepository buildRepoInfo(in Node currentRepository, in string errorPosition) 
in (currentRepository.hasAllMandatoryKeys(errorPosition))
in (currentRepository.hasNoRefTypeConflict(errorPosition))
{
  import std.path : isValidPath;
  printOutput("Fetching repository '" 
          ~ currentRepository["host"].as!string ~ "/" 
          ~ currentRepository["author"].as!string ~ "/" 
          ~ currentRepository["name"].as!string ~ "'");
  if (!isValidPath(currentRepository["localPath"].as!string)) {
    return printParsingErrorAndExit("Local path is not valid.", errorPosition);
  }
  RepositoryReference reference = getReferenceType(currentRepository, errorPosition);
  return new LocalRepository( currentRepository["host"].as!string, 
                              currentRepository["author"].as!string, 
                              currentRepository["name"].as!string, 
                              currentRepository["localPath"].as!string, // TODO: asAbsolutePath ? 
                              reference[0],
                              reference[1],
                              reference[2],
                              getInstallScriptPath(currentRepository, errorPosition));
}

private bool hasNoRefTypeConflict(in Node repoNode, in string errorPosition) {
  if ("commit" in repoNode && "tag" in repoNode) {
    return printParsingErrorAndExit("Keys 'commit' and 'tag' cannot be used together.", errorPosition);
  } else {
    return true;
  }
}

private bool hasAllMandatoryKeys(in Node repoNode, in string errorPosition) {
  string[] missingKeys;
  if ("host" !in repoNode || repoNode["host"].type == NodeType.null_) {
    missingKeys ~= "host";
  }
  if ("author" !in repoNode || repoNode["author"].type == NodeType.null_) {
    missingKeys ~= "author";
  }
  if ("name" !in repoNode || repoNode["name"].type == NodeType.null_) {
    missingKeys ~= "name";
  }
  if ("localPath" !in repoNode || repoNode["localPath"].type == NodeType.null_) {
    missingKeys ~= "localPath";
  }
  if (("commit" !in repoNode || repoNode["commit"].type == NodeType.null_) 
    && ("tag" !in repoNode || repoNode["tag"].type == NodeType.null_)) {
    missingKeys ~= "commit/tag";
  }
  if (missingKeys.length > 0) {
    import std.array : join;
    return printParsingErrorAndExit("The following keys are mandatory and are missing from the Gitfile: " 
                              ~ missingKeys.join(", ") ~ ".", errorPosition);
  } else {
    return true;
  }
}

private RepositoryReference getReferenceType(in Node repoNode, in string errorPosition) {
  if ("commit" in repoNode) {
    return parseCommitReference(repoNode["commit"].as!string, errorPosition);
  } else if ("tag" in repoNode) {
    return parseTagReference(repoNode["tag"].as!string, errorPosition);
  } else {
    printParsingErrorAndExit("Commit/Tag reference not found. Use 'commit' or 'tag' as key for reference.",  errorPosition);
  }
}
/*
private immutable auto latestBranchedRegex = 
  regex(`^(latest)(( on )(?!\\)([^.]((?!(\.\.)|(\/\.)|(\\))([^\^\:\~\s\x00-\x1f\x7f]))*?)(?<!(\.lock)|([\/])))$`);
*/
private immutable auto latestBranchedRegex = 
  regex(`^(latest)(( on )(?!\\)([^.]((?!(\.\.)|(\/\.)|(\\))([^\^\:\~\s]|[\x00-\x1f\x7f]))*?)(?<!(\.lock)|([\/])))$`);

private RepositoryReference parseCommitReference(in string treeReference, in string errorPosition) {
  import std.array : split;
  const auto commitRegex = regex(`^([0-9a-f]{4,40})$`);
  auto shaMatchResult = treeReference.matchAll(commitRegex); // @suppress(dscanner.suspicious.unmodified)
  auto latestMatchResult = treeReference.matchAll(latestBranchedRegex); // @suppress(dscanner.suspicious.unmodified)
  if (!shaMatchResult.empty() && shaMatchResult.hit == treeReference) { // SHA-form matched
    return tuple(TreeReferenceType.COMMIT, treeReference, "");
  } else if (!latestMatchResult.empty() && latestMatchResult.hit == treeReference) { // latest-form matched
    const string[] commitArgs = split(treeReference, " on ");
    return tuple(TreeReferenceType.COMMIT, commitArgs[0], commitArgs.length > 1 ? commitArgs[1] : "master");
  } else {  // No matches. Error!
    printParsingErrorAndExit("Commit reference can be in the form <SHA> or in the form 'latest on <branch>'. "
                              ~ "The branch name must be compliant to the git format. " 
                              ~ "For more information, see https://www.spinics.net/lists/git/msg133704.html .");
  }
}

private RepositoryReference parseTagReference(in string treeReference, in string errorPosition) {
  import std.array : split;
  auto latestMatchResult = treeReference.matchAll(latestBranchedRegex); // @suppress(dscanner.suspicious.unmodified)
  if(!latestMatchResult.empty()) {  // latest-on-branch form matched. Error!
    printParsingErrorAndExit("Tag reference can only be in form '<tag name>' or '<latest>'. You should not specify the branch."); //@suppress(dscanner.style.long_line)
  } else { // tag: <tag-name> ...
    const string[] referenceArray = split(treeReference, " on ");
    if (referenceArray.length > 1) { // <tag> on branch form -> invalid
      printParsingErrorAndExit("Tag reference branch cannot be specified.");
    } else { // tag: <tag-name>
      return tuple(TreeReferenceType.TAG, referenceArray[0], "");
    }
  }
} 

private Option!string getInstallScriptPath(in Node currentRepository, in string errorPosition) {
  import std.path : isValidPath;
  if ("installScript" in currentRepository) {
    string installScriptPath = getFullFilePath(currentRepository["installScript"].as!string);
    if (!isValidPath(installScriptPath)) {
      return printParsingErrorAndExit("Install script path is not valid.", errorPosition);
    }
    return Option!string.some(installScriptPath);
  } else {
    return Option!string.none();
  }
}
