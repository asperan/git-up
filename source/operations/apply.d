module operations.apply;

import std.conv;
import std.file : exists, read;
import core.stdc.stdlib : system, exit;
import std.path : dirSeparator;

import repository;
import utility.logging;
import configuration;

private immutable string gitupLogFile = ".gitup.log";
private immutable string gitupTmpFile = ".gitup.temp";

/**
    Load yaml file and apply the specified configuration.
*/
void apply(string gitfilePath) {
  import file_parser;
  printVerbose("Applying configuration in file \"" ~ gitfilePath ~ "\"...");
  LocalRepository[] repoInfo = loadRepositoriesFromGitfile(gitfilePath);
  foreach (LocalRepository key; repoInfo) {
    printVerbose("Computing action repository \"" ~ key.name ~ "\"...");
    const RepoAction action = computeActionForRepo(key);
    printVerbose("Action: " ~ action.to!string);
    final switch (action) {
      case RepoAction.CLONE:
        handleRepositoryClone(key);  
        goto case;
      case RepoAction.UPDATE:
        handleRepositoryUpdate(key);
        goto case;
      case RepoAction.INSTALL:
        handleRepositoryInstall(key);
        goto case;
      case RepoAction.NOTHING:
        break;
    }
    printOutput("Repository \""~ key.name ~ "\" updated successfully.");
  }
}

private void handleRepositoryClone(in LocalRepository repository) {
  printVerbose("Checking existence of localPath...");
  if (!exists(repository.localPath)) {
    if (Configuration.getInstance.getCreateMissingDirs) {
      printVerbose("Creating new directory at \"" ~ repository.localPath ~ "\"...");
      string dirCreateCommand;
      version(linux) { dirCreateCommand = "mkdir -p"; }
      version(Windows) { dirCreateCommand = "mkdir"; }
      executeCommandString(dirCreateCommand ~ " \"" ~ repository.localPath ~ "\"");
    } else {
      printExecutionError("apply", "Local path does not exist and createMissingDirs option not enabled.");
    }
  }
  printVerbose("Initializing directory...");
  executeCommandAndCheckError("cd \"" ~ repository.localPath ~ "\" && git init", "git init failed.");
  const string remoteURL = repository.host 
                          ~ (repository.host[repository.host.length-1..repository.host.length] == "/" ? "" : "/") //@suppress(dscanner.suspicious.length_subtraction)
                          ~ repository.author ~ "/" 
                          ~ repository.name;
  printVerbose("Adding remote \"" ~ remoteURL ~ "\" named \"origin\"");
  executeCommandAndCheckError("cd \"" ~ repository.localPath ~ "\" && git remote add origin " ~ remoteURL, 
                              "git remote failed to add the origin.");
  printVerbose("Initializing completed.");
}

private void handleRepositoryUpdate(in LocalRepository repository) {
  assert(exists(repository.localPath()), "Local path should exist at this point.");
  printVerbose("Fetching commits and tags from all remote branches...");
  executeCommandAndCheckError("cd \"" ~ repository.localPath() ~ "\" && git fetch --all --tags", 
                              "git fetch could not fetch remote commits.");
  string referenceToMerge;
  if (repository.treeReference() == "latest") {
    printVerbose("Retrieving latest " ~ (repository.refType() == TreeReferenceType.COMMIT ? "commit" : "tag") ~ "...");
    if(changeDirAndExecute(repository.localPath, (repository.refType() == TreeReferenceType.COMMIT ? 
                  "git log origin/" ~ repository.branch() ~ " --first-parent -n 1 --format=\"%H\" " :
                  "git tag --sort=committerdate | tail -n 1") 
              ~ " > " ~ gitupTmpFile)) {
      printExecutionError("apply", "Selected last reference could not be retrieved.");
    }
    referenceToMerge = read(repository.localPath() ~ dirSeparator ~ gitupTmpFile).to!string;
    changeDirAndExecute(repository.localPath, "rm " ~ gitupTmpFile);
  } else {
    referenceToMerge = repository.treeReference();
  }
  printVerbose("Merging " ~ (repository.refType() == TreeReferenceType.COMMIT ? "commit" : "tag") ~ " \"" ~ referenceToMerge ~ "\"..."); //@suppress(dscanner.style.long_line)
  executeCommandAndCheckError("cd \"" ~ repository.localPath() ~ "\" && git merge " ~ referenceToMerge, 
                              "git failed to merge.");
  printVerbose("Update complete.");
}

private void handleRepositoryInstall(in LocalRepository repository) {
  if (!repository.installScriptPath.isEmpty) {
    if (!exists(repository.installScriptPath.get)) {
      printExecutionError("apply", "Install script not found @ " ~ repository.installScriptPath.get);
    } else {
      printVerbose("Install script is specified and exists. Starting execution...");
      if(executeCommandString("(" ~ repository.installScriptPath.get ~ ")")) {
        printExecutionError("apply", "Install script has execution errors.");
      }
    }
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
private RepoAction computeActionForRepo(in LocalRepository repoInfo) {
  if (!exists(repoInfo.localPath()) 
      || changeDirAndExecute(repoInfo.localPath(), "git status > " ~ getNullDevice() ~ " 2>&1")) { // Repository not present
    return Configuration.getInstance.getUpdateOnly ? RepoAction.NOTHING : RepoAction.CLONE;
  } else { // Repository present
    changeDirAndExecute(repoInfo.localPath, (repoInfo.refType == TreeReferenceType.COMMIT ? 
         "git show | head -n 1 | cut -d \" \" -f 2" : 
         "git tag --sort=committerdate | tail -n 1") ~ " > " ~ gitupTmpFile);
    /* system(
      ("cd \"" ~ repoInfo.localPath() ~ "\" && " ~ 
       (repoInfo.refType == TreeReferenceType.COMMIT ? 
         "git show | head -n 1 | cut -d \" \" -f 2" : 
         "git tag --sort=committerdate | tail -n 1") ~ " > .git-updater"
      ).toStringz());*/
    const string currentReference = read(repoInfo.localPath() ~ dirSeparator ~ gitupTmpFile).to!string;
    changeDirAndExecute(repoInfo.localPath, "rm " ~ gitupTmpFile);
    if (repoInfo.treeReference() == currentReference) {
      return Configuration.getInstance.getForceInstall ? RepoAction.INSTALL : RepoAction.NOTHING;
    } else {
      return RepoAction.UPDATE;
    }
  }
}

private void executeCommandAndCheckError(in string command, in string errorMessage) {
  if(executeCommandString(command ~ (Configuration.getInstance.isQuiet ? "" : (" > " ~ getNullDevice())))) {
    printExecutionError("apply", errorMessage);
  }
}

private int changeDirAndExecute(in string directory, in string command) {
  return executeCommandString("cd \"" ~ directory ~ "\" && " ~ command);
}

private int executeCommandString(in string command) {
  import std.string : toStringz;
  return system(command.toStringz());
}
