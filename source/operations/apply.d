module apply;

import std.stdio;
import std.conv;
import std.file;
import core.stdc.stdlib;
import std.string : toStringz;

import file_parser;
import repository;
import file_option;

/**
    Load yaml file and apply the specified configuration.
*/
void apply(string gitfilePath) {
  RuntimeFileOption[] options;
  LocalRepository[] repoInfo;
  loadFile(gitfilePath, options, repoInfo);
  foreach (LocalRepository key; repoInfo)
  {
    const RepoAction action = computeActionForRepo(key, options);
    final switch (action) {
      case RepoAction.CLONE:
        if (!exists(key.localPath())) {
          if (searchBooleanOption("createMissingDirs", options)) {
            string dirCreateCommand;
            version(linux) { dirCreateCommand = "mkdir -p"; }
            version(Windows) { dirCreateCommand = "mkdir"; }
            system((dirCreateCommand ~ " '" ~ key.localPath() ~ "'").toStringz());
          } else {
            printExecutionError("apply", "Local path does not exist and createMissingDirs option not enabled.");
          }
        }
        executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && git init", "git init failed.");
        const string remoteURL = key.host() 
                                ~ (key.host()[key.host().length-1..key.host().length] == "/" ? "" : "/") //@suppress(dscanner.suspicious.length_subtraction)
                                ~ key.author() ~ "/" 
                                ~ key.name();
        executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && git remote add origin " ~ remoteURL, 
                                    "git remote failed to add the origin.");
      goto case;
      case RepoAction.UPDATE:
        assert(exists(key.localPath()), "Local path should exist at this point.");
        // TODO: maybe redirect output
        executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && git fetch --all --tags", 
                                    "git fetch could not fetch remote commits.");
        string referenceToMerge;
        if (key.treeReference() == "latest") {
          executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && " 
                                      ~ (key.refType() == TreeReferenceType.COMMIT ? 
                                        "git log origin/" ~ key.branch() ~ " --first-parent -n 1 --format=\"%H\" " :
                                        "git tag --sort=committerdate | tail -n 1") 
                                      ~ " > .git-updater", "Selected last reference could not be retrieved.");
          referenceToMerge = read(key.localPath() ~ "/.git-updater").to!string;
        } else {
          referenceToMerge = key.treeReference();
        }
        // TODO: maybe redirect output
        executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && git merge " ~ referenceToMerge, 
                                    "git failed to merge.");
        goto case;
      case RepoAction.INSTALL:
        if (key.installScriptPath() != "") {
          if (!exists(key.installScriptPath())) {
            printExecutionError("apply", "Install script not found @ " ~ key.installScriptPath());
          } else {
            if(system(("(" ~ key.installScriptPath() ~ ")").toStringz())) {
              printExecutionError("apply", "Install script has execution errors.");
            }
          }
        }
        goto case;
      case RepoAction.NOTHING:
        break;
    }
    writeln(key.fullName() ~ " updated.");
  }
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

  string nullDevice;
  version(linux) { nullDevice = "/dev/null"; }
  version(Windows) { nullDevice = "NUL"; }
  if (!exists(repoInfo.localPath()) 
      || system(("cd '" ~ repoInfo.localPath() ~ "' && git status > " ~ nullDevice ~ " 2>&1").toStringz())) { // Repository not present
    return searchBooleanOption("updateOnly", options) ? RepoAction.NOTHING : RepoAction.CLONE;
  } else { // Repository present
    system(
      ("cd '" ~ repoInfo.localPath() ~ "' && " ~ 
       (repoInfo.refType == TreeReferenceType.COMMIT ? 
         "git show | head -n 1 | cut -d ' ' -f 2" : 
         "git tag --sort=committerdate | tail -n 1") ~ " > .git-updater"
      ).toStringz());
    const string currentReference = read(repoInfo.localPath() ~ "/.git-updater").to!string;
    system(("cd '" ~ repoInfo.localPath() ~ "' && rm .git-updater").toStringz());
    if (repoInfo.treeReference() == currentReference) {
      return searchBooleanOption("forceInstall", options) ? RepoAction.INSTALL : RepoAction.NOTHING;
    } else {
      return RepoAction.UPDATE;
    }
  }
}

private void doActionForRepo(in string action, in string repoInfo) {

}

private void printExecutionError(in string operation, in string errorMessage) {
  stderr.writeln("Execution error for " ~ operation ~ ": " ~ errorMessage);
  exit(1);
  assert(0);
}

private void executeCommandAndCheckError(in string command, in string errorMessage) {
  if(system(command.toStringz())) {
    printExecutionError("apply", errorMessage);
  }
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