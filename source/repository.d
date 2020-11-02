module repository;

import std.regex;

private immutable auto commitRegex = regex(`([0-9a-f]{4,40})`);

/**
    Reference type. It can be a commit or a tag.
*/
enum TreeReferenceType {
      COMMIT, TAG
}

/**
    Local repository object. Represents a local repository based on the cloned remote repository and the local path where it is cloned.
*/
struct LocalRepository {
  private:
    string host;
    string author;
    string name;

    string localPath;

    TreeReferenceType refType;
    string treeReference;

    string installScriptPath;

  public:
    /**
        Creates a new LocalRepository.
        'host' is where the repository is hosted, i.e. https://github.com or a private repository mirror.
        'installScriptPath', if empty, is not executed.
    */
    this( string host, 
          string author, 
          string name, 
          string localPath, 
          TreeReferenceType treeReferenceType,
          string treeReference,
          string installScriptPath)
    in {
      if (treeReferenceType == TreeReferenceType.COMMIT) {
        auto matchResult = treeReference.matchAll(commitRegex); // @suppress(dscanner.suspicious.unmodified)
        assert(matchResult.front.hit == treeReference);
      }
    } 
    do {
      this.host = host;
      this.author = author;
      this.name = name;
      this.localPath = localPath;
      this.refType = treeReferenceType;
      this.treeReference = treeReference;
      this.installScriptPath = installScriptPath;
    }

}

unittest {
  LocalRepository("foo", "bar", "foobar", "barfoo", TreeReferenceType.COMMIT, "4f942", "");
  LocalRepository("foo", "bar", "foobar", "barfoo", TreeReferenceType.COMMIT, "07a0", "");
}