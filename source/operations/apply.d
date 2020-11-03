module apply;

import std.stdio;
import dyaml;
import repository;
import core.stdc.stdlib;
import std.conv;
import std.array;
import std.file;
import std.uni;

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
    writeln("Option '" ~ key ~ "' has value '" ~ value.parseBooleanLiteral(key).to!string ~ "'.");
  }
  for (int i = 0; i < root["Repositories"].length; i++ ) {
    repoInfo ~= buildRepoInfo(root["Repositories"][i], " @ " ~ toShortOrdinal(i + 1) ~ " repository");
  }
}

private LocalRepository buildRepoInfo(in Node currentRepository, in string errorPosition) 
in (currentRepository.hasAllMandatoryKeys(errorPosition))
in (currentRepository.hasNoRefTypeConflict(errorPosition))
{
  writeln("Fetching repository '" 
          ~ currentRepository["host"].as!string ~ "/" 
          ~ currentRepository["author"].as!string ~ "/" 
          ~ currentRepository["name"].as!string ~ "'");
  TreeReferenceType referenceType;
  string referenceTypeString;
  getReferenceType(currentRepository, errorPosition, referenceType, referenceTypeString);
  string installScriptPath;
  if ("installScript" in currentRepository) {
    installScriptPath = parseFilePath(currentRepository["installScript"].as!string);
    if (!exists(installScriptPath)) {
      printParsingErrorAndExit("Specified install script does not exist.", errorPosition);
    }
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
                              ~ missingKeys.join(", ") ~ ".", errorPosition);
    return false;
  } else {
    return true;
  }
}

private void getReferenceType(in Node repoNode, 
                              in string errorPosition, 
                              out TreeReferenceType type, 
                              out string typeString) {
  if ("commit" in repoNode) {
    type = TreeReferenceType.COMMIT;
    typeString = "commit";
  } else if ("tag" in repoNode) {
    type = TreeReferenceType.TAG;
    typeString = "tag";
  } else {
    printParsingErrorAndExit("Commit/Tag reference not found. Use 'commit' or 'tag' as key for reference.", 
                              errorPosition);
  }
}

private string toShortOrdinal(int i) 
in (i>0)
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

private void printParsingErrorAndExit(in string errorMessage, in string additionalInfo = "") {
  stderr.writeln("Parsing error" 
                  ~ additionalInfo
                  ~ ": " ~ errorMessage);
  exit(1);
}

private bool parseBooleanLiteral(in string input, in string optionName) {
  switch (input.toLower()) {
    case "y":
    case "yes":
    case "true":
    case "on":
      return true;
    case "n":
    case "no":
    case "false":
    case "off":
      return false;
    default:
      printParsingErrorAndExit("Value '" ~ input ~  "' cannot be parsed into a boolean.", " @ option " ~ optionName );
      assert(0);
  }
}