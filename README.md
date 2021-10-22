# git-up
Git-up is a command-line software to manage installation and update of repositories.

### Version 1.0.0 target features
* [x] Global option: updateOnly -> on run do not download new repository.
* [x] Apply a simple configuration (with no sublevels).
* [x] Update a repository to the latest tag.

### Subsequent versions target features
* [ ] Operation 'check' which notifies whether there are updates available.
* [ ] Parallelize execution of clones/updates.
* [ ] Enable full support for Windows.
* [x] Update the repository to the latest commit on a branch.
* [ ] Parse multiple files in a single call.
* [x] Option for verbose output.
* [x] Prettify help string.

## Getting started
### Prerequisites
1. Download a D compiler from [the official D website](https://dlang.org/download.html) or your OS package manager.

1. Download the DUB package manager. Like the D compiler, it can be found in OS package managers. For windows, look in [the official release page](https://github.com/dlang/dub/releases).

### Compile git-updater
Clone the repository with `git clone https://github.com/asperan/git-up.git` in a folder of your choice, then `cd` into that folder and run `dub build`.

DUB creates a file called `git-up`. If it is not executable, add execution permissions to the file.

To view the help panel, execute `./git-up.exe --help`.

### Use pre-compiled executable
From the release page, download the correct executable and enable execution for the file.

----

## Operations
**apply**: apply the specified configuration, that is, download and install the repository which it cannot find locally and, if different from the current one, it merge the repository up to the specified tag or commit.

----


## Gitfile example
```
GlobalOptions:
  updateOnly: y # Boolean (default value: false); If enabled, no repository will be cloned ex-novo
  forceInstall: y # Boolean (default value: false); If enabled, even if there is no update, the install script is run.
  createMissingDirs: y # Boolean (default value: false); If enabled, when cloning the repo, missing directories are created.

Repositories:
  - host: https://github.com # The host must contain the protocol ('https://')
    author: gto76
    name: python-cheatsheet
    commit: latest on master # commit accepts the sha form (a string with 4 to 40 characters) or "latest on <branch>"
    localPath: /path/to/git-root/directory 
  - host: https://gitlab.com
    author: tildes
    name: tildes
    tag: v0.7.0 # tag accepts the tag name or "latest"
    localPath: a/relative/path/to/git-root/directory
    installScript: path/to/install/script # Optional; can be inside the repository directory.
```

### Notes

* Absolute path are preferred, as relative path changes when changing working directory.
* The localPath field points to the folder in which there will be the repository; it can be non-existent if the option `createMissingDirs` is true. For example, if the wanted repository is `python-cheatsheet` from *gto76* (first one in the Gitfile example), its localPath can be `/home/user/repos/python-cheatsheet`.
* On the local side, the used branch is 'master', even if the remote has another name.
* The dyaml library does **not** recognize tabs as whitespaces, so you **must** indent the Gitfile with spaces.

----

## Known issues
* Switching from 'commit' to 'tag or vice versa can cause problems as there could not be a path forward to the new reference.
