# git-update
Git-update is a command-line software to manage installation and update of repositories.

### Operations
**apply**: apply the specified configuration, that is, download and install the repository which it cannot find locally and, if different from the current one, it merge the repository up to the specified tag or commit.

### Version 1.0.0 target features
* [ ] Global option: update_only -> on run do not download new repository.
* [ ] Apply a simple configuration (with no sublevels).
* [ ] Update a repository to the latest tag.

### Subsequent versions target features
* [ ] Operation 'check' which notifies whether there are updates available.
* [ ] Parallelize execution of clones/updates.
* [ ] Enable support for Windows.
* [ ] Update the repository to the latest commit on a branch.
* [ ] Parse multiple files in a single call.


### Known issues
* Switching from 'commit' to 'tag or vice versa can cause problems as there could not be a path forward to the new reference.
