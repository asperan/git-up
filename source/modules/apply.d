module apply;

import std.stdio;
import dyaml;
import repository;
import core.stdc.stdlib;
import std.conv;
import std.array;

/**
    Load yaml file and apply the specified configuration.
*/
void apply(string gitfilePath) {
  bool[string] options;
  string repoInfo;
  loadFile(gitfilePath, options, repoInfo);
  writefln("Searching gitfile: " ~ (gitfilePath == null ? "Gitfile" : gitfilePath ));
}

private void loadFile(in string filePath, out bool[string] fileOptions, out string repoInfo) {
  Node root = Loader.fromFile(filePath).load();
  foreach (string key, string value ; root["GlobalOptions"])
  {
    writeln("Option '" ~ key ~ "' as value '" ~ value ~ "'.");
  }
  for (int i = 0; i < root["Repositories"].length; i++ ) {
    assert(hasAllMandatoryKeys(root["Repositories"][i]));
    writeln("Fetching repository '" ~ root["Repositories"][i]["host"].as!string ~ "/" ~ root["Repositories"][i]["author"].as!string ~ "/" ~ root["Repositories"][i]["name"].as!string ~ "'");
    TreeReferenceType referenceType;
    string referenceTypeString;
    getReferenceType(root["Repositories"][i], referenceType, referenceTypeString);
    string installScriptPath = "";
    LocalRepository LR = LocalRepository( root["Repositories"][i]["host"].as!string, 
                                          root["Repositories"][i]["author"].as!string, 
                                          root["Repositories"][i]["name"].as!string, 
                                          root["Repositories"][i]["localPath"].as!string, 
                                          referenceType,
                                          root["Repositories"][i][referenceTypeString].as!string, 
                                          installScriptPath);        
  }
}

private void checkActionForRepo(in string repoInfo) {

}

private void doActionForRepo(in string action, in string repoInfo) {

}

private string parseFilePath(in string localPath) {
  return null;
}

private bool hasAllMandatoryKeys(in Node repoNode) {
  string[] missingKeys;
  if ( ("host" !in repoNode) ) {
    missingKeys ~= "host";
  }
  if ( ("author" !in repoNode) ) {
    missingKeys ~= "author";
  }
  if ( ("name" !in repoNode) ) {
    missingKeys ~= "name";
  }
  if ( ("localPath" !in repoNode) ) {
    missingKeys ~= "localPath";
  }
  if ( ("commit" !in repoNode) && ("tag" !in repoNode) ) {
    missingKeys ~= "commit/tag";
  }
  if (missingKeys.length > 0) {
    printParsingErrorAndExit("The following keys are mandatory and are missing from the Gitfile: " ~ missingKeys.join(", "));
    return false;
  } else {
    return true;
  }
}

private void getReferenceType(in Node repoNode, out TreeReferenceType type, string typeString) {
  if (("commit" in repoNode) != null ) {
    type = TreeReferenceType.COMMIT;
    typeString = "commit";
  } else if (("tag" in repoNode) != null) {
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