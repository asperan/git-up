module apply;

import std.stdio;
import std.conv;
import std.file : exists, read;
import core.stdc.stdlib : system, exit;
import std.string : toStringz;

import file_parser;
import repository;
import file_option;
import print_help : printVerbose;

/**
    Load yaml file and apply the specified configuration.
*/
void apply(string gitfilePath) {
  printVerbose("Applying configuration in file '" ~ gitfilePath ~ "'...");
  RuntimeFileOption[] options;
  LocalRepository[] repoInfo;
  loadFile(gitfilePath, options, repoInfo);
  foreach (LocalRepository key; repoInfo)
  {
    printVerbose("Computing action repository '" ~ key.fullName() ~ "'...");
    const RepoAction action = computeActionForRepo(key, options);
    printVerbose("Action: " ~ action.to!string);
    final switch (action) {
      case RepoAction.CLONE:
        printVerbose("Checking existence of localPath...");
        if (!exists(key.localPath())) {
          if (searchBooleanOption("createMissingDirs", options)) {
            printVerbose("Creating new directory at '" ~ key.localPath() ~ "'...");
            string dirCreateCommand;
            version(linux) { dirCreateCommand = "mkdir -p"; }
            version(Windows) { dirCreateCommand = "mkdir"; }
            system((dirCreateCommand ~ " '" ~ key.localPath() ~ "'").toStringz());
          } else {
            printExecutionError("apply", "Local path does not exist and createMissingDirs option not enabled.");
          }
        }
        printVerbose("Initializing directory...");
        executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && git init", "git init failed.");
        const string remoteURL = key.host() 
                                ~ (key.host()[key.host().length-1..key.host().length] == "/" ? "" : "/") //@suppress(dscanner.suspicious.length_subtraction)
                                ~ key.author() ~ "/" 
                                ~ key.name();
        printVerbose("Adding remote '" ~ remoteURL ~ "' named 'origin'");
        executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && git remote add origin " ~ remoteURL, 
                                    "git remote failed to add the origin.");
        printVerbose("Initializing completed.");  
      goto case;
      case RepoAction.UPDATE:
        assert(exists(key.localPath()), "Local path should exist at this point.");
        // TODO: maybe redirect output
        printVerbose("Fetching commits and tags from all remote branches...");
        executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && git fetch --all --tags", 
                                    "git fetch could not fetch remote commits.");
        string referenceToMerge;
        if (key.treeReference() == "latest") {
          printVerbose("Retrieving latest " ~ (key.refType() == TreeReferenceType.COMMIT ? "commit" : "tag") ~ "...");
          executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && " 
                                      ~ (key.refType() == TreeReferenceType.COMMIT ? 
                                        "git log origin/" ~ key.branch() ~ " --first-parent -n 1 --format=\"%H\" " :
                                        "git tag --sort=committerdate | tail -n 1") 
                                      ~ " > .git-updater", "Selected last reference could not be retrieved.");
          referenceToMerge = read(key.localPath() ~ "/.git-updater").to!string;
          system(("cd '" ~ key.localPath() ~ "' && rm .git-updater").toStringz());
        } else {
          referenceToMerge = key.treeReference();
        }
        printVerbose("Merging " ~ (key.refType() == TreeReferenceType.COMMIT ? "commit" : "tag") ~ " '" ~ referenceToMerge ~ "'..."); //@suppress(dscanner.style.long_line)
        // TODO: maybe redirect output
        executeCommandAndCheckError("cd '" ~ key.localPath() ~ "' && git merge " ~ referenceToMerge, 
                                    "git failed to merge.");
        printVerbose("Update complete.");
        goto case;
      case RepoAction.INSTALL:
        if (key.installScriptPath() != "") {
          if (!exists(key.installScriptPath())) {
            printExecutionError("apply", "Install script not found @ " ~ key.installScriptPath());
          } else {
            printVerbose("Install script is specified and exists. Starting execution...");
            if(system(("(" ~ key.installScriptPath() ~ ")").toStringz())) {
              printExecutionError("apply", "Install script has execution errors.");
            }
          }
        }
        goto case;
      case RepoAction.NOTHING:
        break;
    }
    writeln("Repository '"~ key.fullName() ~ "' updated successfully.");
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
