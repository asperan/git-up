module file_parser;

import std.file;
import std.stdio;
import std.conv;
import std.array;
import std.uni;

import repository;
import parsing_utils;
import file_option;
import dyaml;

/**
    Loads Gitfile if it exists.
    Parses options and repository informations.
*/
void loadFile(in string filePath, out RuntimeFileOption[] fileOptions, out LocalRepository[] repoInfo) {
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
  return new LocalRepository( currentRepository["host"].as!string, 
                              currentRepository["author"].as!string, 
                              currentRepository["name"].as!string, 
                              currentRepository["localPath"].as!string, 
                              referenceType,
                              currentRepository[referenceTypeString].as!string, 
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

private void assertValueUniqueness(T : NamedParsable) (in T[] values, in string valuesName) 
{
  if (values.length > 0) {
    for (int i = 0; i < values.length - 1; i++) { // @suppress(dscanner.suspicious.length_subtraction)
      for (int j = 1; j < values.length; j++) {
        if (values[i] == values[j]) {
          printParsingErrorAndExit("Duplicate value '" ~ values[i].name() ~ "' found. Aborting.", " @ " ~ valuesName);
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