module apply;

import std.stdio;

import file_parser;
import repository;
import file_option;
import std.conv;
import std.file;

/**
    Load yaml file and apply the specified configuration.
*/
void apply(string gitfilePath) {
  RuntimeFileOption[] options;
  LocalRepository[] repoInfo;
  loadFile(gitfilePath, options, repoInfo);
  // TODO: check actions to do for repositories
  // TODO: execute actions
  foreach (LocalRepository key; repoInfo)
  {
    writeln(computeActionForRepo(key, options).to!string);
  }
  writefln("Searching gitfile: " ~ (gitfilePath == null ? "Gitfile" : gitfilePath ));
}

/** Action to execute on a repository declaration. 
    Ideally, the first action implies the following ones,
    i.e. cloning implies updating and installing;
      updating implies installing.
*/
private enum RepoAction {
  CLONE,
  UPDATE,
  INSTALL,
  NOTHING
}

/** Returns the action to do for a specified repository, based on the active options. */
private RepoAction computeActionForRepo(in LocalRepository repoInfo, in RuntimeFileOption[] options) {
  import std.file : exists;
  import core.stdc.stdlib : system;
  import std.string : toStringz;

  string nullDevice;
  version(linux) { nullDevice = "/dev/null"; }
  version(Windows) { nullDevice = "NUL"; }
  if (!exists(repoInfo.localPath()) 
      || system(("cd " ~ repoInfo.localPath() ~ "; git status > " ~ nullDevice ~ " 2>&1").toStringz())) { // Repository not present
    return searchBooleanOption("updateOnly", options) ? RepoAction.NOTHING : RepoAction.CLONE;
  } else { // Repository present
    system(
      ("cd " ~ repoInfo.localPath() ~ "; " ~ 
       (repoInfo.refType == TreeReferenceType.COMMIT ? 
         "git show | head -n 1 | cut -d ' ' -f 2" : 
         "git tag --sort=committerdate | tail -n 1") ~ " > .git-updater"
      ).toStringz());
    const string currentReference = read(repoInfo.localPath() ~ "/.git-updater").to!string;
    system(("cd " ~ repoInfo.localPath() ~ "; rm .git-updater").toStringz());
    if (repoInfo.treeReference() == currentReference) {
      return searchBooleanOption("forceInstall", options) ? RepoAction.INSTALL : RepoAction.NOTHING;
    } else {
      return RepoAction.UPDATE;
    }
  }
}

private void doActionForRepo(in string action, in string repoInfo) {

}

/** Return the value of a runtime option if present. The default value otherwise. */
private bool searchBooleanOption(in string name, in RuntimeFileOption[] options) {
  foreach (key; options) {
    if (key == name) {
      assert(key.type() == ArgumentType.BOOL, "searchBooleanOption called on a non-boolean option");
      return key.argBool();
    }
  }
  foreach (key; fileOptions)
  {
    if (key == name) {
      assert(key.argType() == ArgumentType.BOOL, "searchBooleanOption called on a non-boolean option");
      return key.defaultBool();
    }
  }
  assert(0, "Option '" ~ name ~ "' not recognized.");
}

private int searchIntegerOption(in string name, in RuntimeFileOption[] options) {
  foreach (key; options) {
    if (key == name) {
      assert(key.type() == ArgumentType.INT, "searchIntegerOption called on a non-integer option");
      return key.argInt();
    }
  }
  foreach (key; fileOptions)
  {
    if (key == name) {
      assert(key.argType() == ArgumentType.INT, "searchIntegerOption called on a non-integer option");
      return key.defaultInt();
    }
  }
  assert(0, "Option '" ~ name ~ "' not recognized.");
}

private string searchStringOption(in string name, in RuntimeFileOption[] options) {
  foreach (key; options) {
    if (key == name) {
      assert(key.type() == ArgumentType.STRING, "searchStringOption called on a non-string option");
      return key.argString();
    }
  }
  foreach (key; fileOptions)
  {
    if (key == name) {
      assert(key.argType() == ArgumentType.STRING, "searchStringOption called on a non-string option");
      return key.defaultString();
    }
  }
  assert(0, "Option '" ~ name ~ "' not recognized.");
}