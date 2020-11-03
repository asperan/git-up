module apply;

import std.stdio;

import file_parser;
import repository;

/**
    Load yaml file and apply the specified configuration.
*/
void apply(string gitfilePath) {
  bool[string] options;
  LocalRepository[] repoInfo;
  loadFile(gitfilePath, options, repoInfo);
  writefln("Searching gitfile: " ~ (gitfilePath == null ? "Gitfile" : gitfilePath ));
}

private void checkActionForRepo(in string repoInfo) {

}

private void doActionForRepo(in string action, in string repoInfo) {

}
