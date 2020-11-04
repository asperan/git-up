module file_parser;

import std.stdio;
import std.regex;

import repository;
import parsing_utils;
import file_option;
import dyaml;

/**
    Loads Gitfile if it exists.
    Parses options and repository informations.
*/
void loadFile(in string filePath, out RuntimeFileOption[] fileOptions, out LocalRepository[] repoInfo) {
  import std.file : exists;
  string parsedFilePath = parseFilePath(filePath);
  if (!exists(parsedFilePath)) {
    printParsingErrorAndExit("Gitfile '" ~ parsedFilePath ~ "' does not exist.");
  }
  Node root = Loader.fromFile(parsedFilePath).load();
  foreach (string key, string value ; root["GlobalOptions"])
  {
    fileOptions ~= buildFileOption(key, value);
  }
  assertValueUniqueness!(RuntimeFileOption)(fileOptions, "GlobalOptions");
  for (int i = 0; i < root["Repositories"].length; i++ ) {
    repoInfo ~= buildRepoInfo(root["Repositories"][i], " @ " ~ toShortOrdinal(i + 1) ~ " repository");
  }
  assertValueUniqueness!(LocalRepository)(repoInfo, "Repositories");
}

private LocalRepository buildRepoInfo(in Node currentRepository, in string errorPosition) 
in (currentRepository.hasAllMandatoryKeys(errorPosition))
in (currentRepository.hasNoRefTypeConflict(errorPosition))
{
  import std.path : isValidPath;
  writeln("Fetching repository '" 
          ~ currentRepository["host"].as!string ~ "/" 
          ~ currentRepository["author"].as!string ~ "/" 
          ~ currentRepository["name"].as!string ~ "'");
  if (!isValidPath(currentRepository["localPath"].as!string)) {
    printParsingErrorAndExit("Local path is not valid.", errorPosition);
  }
  TreeReferenceType referenceType;
  string referenceString;
  string branchString;
  getReferenceType(currentRepository, errorPosition, referenceType, referenceString, branchString);
  string installScriptPath;
  if ("installScript" in currentRepository) {
    installScriptPath = parseFilePath(currentRepository["installScript"].as!string);
    if (!isValidPath(installScriptPath)) {
      printParsingErrorAndExit("Install script path is not valid.", errorPosition);
    }
  } else {
    installScriptPath = "";
  }
  return new LocalRepository( currentRepository["host"].as!string, 
                              currentRepository["author"].as!string, 
                              currentRepository["name"].as!string, 
                              currentRepository["localPath"].as!string, 
                              referenceType,
                              referenceString,
                              branchString,
                              installScriptPath);
}

private bool hasNoRefTypeConflict(in Node repoNode, in string errorPosition) {
  if ("commit" in repoNode && "tag" in repoNode) {
    printParsingErrorAndExit("Keys 'commit' and 'tag' cannot be used together.", errorPosition);
    return false;
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
    printParsingErrorAndExit("The following keys are mandatory and are missing from the Gitfile: " 
                              ~ missingKeys.join(", ") ~ ".", errorPosition);
    return false;
  } else {
    return true;
  }
}

private immutable auto commitRegex = regex(`^([0-9a-f]{4,40})$`);
private immutable auto latestBranchedRegex = 
  regex(`^(latest)(( on )(?!\\)([^.]((?!(\.\.)|(\/\.)|(\\))([^\^\:\~\s\x00-\x1f\x7f]))*?)(?<!(\.lock)|([\/])))$`);

private void getReferenceType(in Node repoNode, 
                              in string errorPosition, 
                              out TreeReferenceType type, 
                              out string referenceString,
                              out string branchString) {
  import std.array : array_split = split;
  if ("commit" in repoNode) {
    type = TreeReferenceType.COMMIT;
    string treeReference = repoNode["commit"].as!string;
    auto shaMatchResult = treeReference.matchAll(commitRegex); // @suppress(dscanner.suspicious.unmodified)
    auto latestMatchResult = treeReference.matchAll(latestBranchedRegex); // @suppress(dscanner.suspicious.unmodified)
    if (!shaMatchResult.empty() && shaMatchResult.front.hit == treeReference) { // SHA-form matched
      referenceString = treeReference;
      branchString = "";
    } else if (!latestMatchResult.empty() && latestMatchResult.front.hit == treeReference) { // latest-form matched
      const string[] commitArgs = array_split(treeReference, " on ");
      referenceString = commitArgs[0];
      branchString = commitArgs.length > 1 ? commitArgs[1] : "master";
    } else {  // No matches. Error!
      printParsingErrorAndExit("Commit reference can be in the form <SHA> or in the form 'latest on <branch>'. "
                                ~ "The branch name must be compliant to the git format. " 
                                ~ "For more information, see https://www.spinics.net/lists/git/msg133704.html .");
      assert(0);
    }
  } else if ("tag" in repoNode) {
    type = TreeReferenceType.TAG;
    string treeReference = repoNode["tag"].as!string;
    auto latestMatchResult = treeReference.matchAll(latestBranchedRegex); // @suppress(dscanner.suspicious.unmodified)
    if(!latestMatchResult.empty()) {  // latest-on-branch form matched. Error!
      printParsingErrorAndExit("Tag reference can only be in form '<tag name>' or '<latest>'. You should not specify the branch."); //@suppress(dscanner.style.long_line)
      assert(0);
    } else {
      const string[] referenceArray = array_split(treeReference, " on ");
      if (referenceArray.length > 1) {
        printParsingErrorAndExit("Tag reference branch cannot be specified.");
        assert(0);
      }
      referenceString = referenceArray[0];
      branchString = "";
    }
  } else {
    printParsingErrorAndExit("Commit/Tag reference not found. Use 'commit' or 'tag' as key for reference.", 
                              errorPosition);
  }
}

private string toShortOrdinal(int i) 
in (i>0)
{
  import std.conv : to;
  if (i >= 11 && i <= 13) { // Special cases
    return i.to!string(10) ~ "th";
  } else {
    switch (i % 10) {
      case 1:
        return i.to!string(10) ~ "st";
      case 2:
        return i.to!string(10) ~ "nd";
      case 3:
        return i.to!string(10) ~ "rd";
      default:
        return i.to!string(10) ~ "th";
    }
  }
}

unittest {
  assert(1.toShortOrdinal() == "1st");
  assert(11.toShortOrdinal() == "11th");
  assert(22.toShortOrdinal() == "22nd");
}

private void assertValueUniqueness(T : NamedParsable) (in T[] values, in string valuesName) 
{
  if (values.length > 0) {
    for (int i = 0; i < values.length - 1; i++) { // @suppress(dscanner.suspicious.length_subtraction)
      for (int j = 1; j < values.length; j++) {
        if (values[i] == values[j]) {
          printParsingErrorAndExit("Duplicate value '" ~ values[i].fullName() ~ "' found. Aborting.", " @ " ~ valuesName);
        }
      }
    }
  }
}

private RuntimeFileOption buildFileOption(in string key, in string value)
in (key.length > 0)
in (value.length > 0) 
{
  immutable FileOption* fo = searchFileOption(key);
  assert(fo, "This FileOptions should not be null!");
  if (value == "null") {
    printParsingErrorAndExit("'null' value passed to option '" ~ key ~ "'.");
    return null;
  } else {
    final switch (fo.argType()) {
      case ArgumentType.BOOL:
        return new RuntimeFileOption(fo, value.parseBooleanLiteral(key));
      case ArgumentType.INT:
        return new RuntimeFileOption(fo, 0);
      case ArgumentType.STRING:
        return new RuntimeFileOption(fo, value);
    }
  }
}