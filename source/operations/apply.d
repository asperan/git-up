module apply;

import std.stdio;
import dyaml;
import repository;
import core.stdc.stdlib;
import std.conv;
import std.array;
import std.file;

/**
    Load yaml file and apply the specified configuration.
*/
void apply(string gitfilePath) {
  bool[string] options;
  LocalRepository[] repoInfo;
  loadFile(gitfilePath, options, repoInfo);
  writefln("Searching gitfile: " ~ (gitfilePath == null ? "Gitfile" : gitfilePath ));
}

private void loadFile(in string filePath, out bool[string] fileOptions, out LocalRepository[] repoInfo) {
  string parsedFilePath = parseFilePath(filePath);
  if (!exists(parsedFilePath)) {
    printParsingErrorAndExit("Gitfile '" ~ parsedFilePath ~ "' does not exist.");
  }
  Node root = Loader.fromFile(parsedFilePath).load();
  // TODO: manage options
  foreach (string key, string value ; root["GlobalOptions"])
  {
    // parse value to boolean
    writeln("Option '" ~ key ~ "' has value '" ~ value ~ "'.");
  }
  for (int i = 0; i < root["Repositories"].length; i++ ) {
    repoInfo ~= buildRepoInfo(root["Repositories"][i]);
  }
}

private LocalRepository buildRepoInfo(in Node currentRepository) {
  assert(currentRepository.hasAllMandatoryKeys());
  // assert there are not both 'commit' and 'tag'
  writeln("Fetching repository '" 
          ~ currentRepository["host"].as!string ~ "/" 
          ~ currentRepository["author"].as!string ~ "/" 
          ~ currentRepository["name"].as!string ~ "'");
  TreeReferenceType referenceType;
  string referenceTypeString;
  getReferenceType(currentRepository, referenceType, referenceTypeString);
  // TODO: Check existance of install script if specified.
  string installScriptPath;
  if ("installScript" in currentRepository) {
    installScriptPath = currentRepository["installScript"].as!string;
  } else {
    installScriptPath = "";
  }
  return LocalRepository( currentRepository["host"].as!string, 
                          currentRepository["author"].as!string, 
                          currentRepository["name"].as!string, 
                          currentRepository["localPath"].as!string, 
                          referenceType,
                          currentRepository[referenceTypeString].as!string, 
                          installScriptPath);
}

private void checkActionForRepo(in string repoInfo) {

}

private void doActionForRepo(in string action, in string repoInfo) {

}

private string parseFilePath(in string filePath) {
  if (filePath[0..1] == "/") { // Absolute path, no transformation needed
    return filePath;
  } else { // Relative path, prepend the current directory
    return getcwd() ~ "/" ~ filePath;
  }
}

private bool hasAllMandatoryKeys(in Node repoNode) {
  string[] missingKeys;
  if ("host" !in repoNode) {
    missingKeys ~= "host";
  }
  if ("author" !in repoNode) {
    missingKeys ~= "author";
  }
  if ("name" !in repoNode) {
    missingKeys ~= "name";
  }
  if ("localPath" !in repoNode) {
    missingKeys ~= "localPath";
  }
  if (("commit" !in repoNode) && ("tag" !in repoNode)) {
    missingKeys ~= "commit/tag";
  }
  if (missingKeys.length > 0) {
    printParsingErrorAndExit("The following keys are mandatory and are missing from the Gitfile: " 
                              ~ missingKeys.join(", "));
    return false;
  } else {
    return true;
  }
}

private void getReferenceType(in Node repoNode, out TreeReferenceType type, out string typeString) {
  if ("commit" in repoNode) {
    type = TreeReferenceType.COMMIT;
    typeString = "commit";
  } else if ("tag" in repoNode) {
    type = TreeReferenceType.TAG;
    typeString = "tag";
  } else {
    printParsingErrorAndExit("Commit/Tag reference not found. Use 'commit' or 'tag' as key for reference.");
  }
}

private string toShortOrdinal(int i) 
in {
  assert(i>0);
}
do
{
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

private void printParsingErrorAndExit(in string errorMessage) {
  stderr.writeln("Parsing error: " ~ errorMessage);
  exit(1);
}