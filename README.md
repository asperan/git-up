# git-update
Git-update is a command-line software to manage installation and update of repositories.

### Operations
**apply**: apply the specified configuration, that is, download and install the repository which it cannot find locally and, if different from the current one, it merge the repository up to the specified tag or commit.

### Version 1.0.0 target features
* [✓] Global option: update_only -> on run do not download new repository.
* [✓] Apply a simple configuration (with no sublevels).
* [✓] Update a repository to the latest tag.

### Subsequent versions target features
* [ ] Operation 'check' which notifies whether there are updates available.
* [ ] Parallelize execution of clones/updates.
* [ ] Enable full support for Windows.
* [✓] Update the repository to the latest commit on a branch.
* [ ] Parse multiple files in a single call.
* [ ] Option for verbose output

### Gitfile example
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

**Notes**
* Absolute path are preferred, as relative path changes when changing working directory.
* On the local side, the used branch is 'master', even if the remote has another name.

### Known issues
* Switching from 'commit' to 'tag or vice versa can cause problems as there could not be a path forward to the new reference.