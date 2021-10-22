module repository;

import asperan.option;

/**
    Reference type. It can be a commit or a tag.
*/
enum TreeReferenceType {
      COMMIT, TAG
}

/**
    Local repository object. Represents a local repository based on the cloned remote repository and the local path where it is cloned.
*/
class LocalRepository {
  private:
    string p_host;
    string p_author;
    string p_name;

    string p_localPath;

    TreeReferenceType p_refType;
    string p_treeReference;
    string p_branch;

    Option!string p_installScriptPath;

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
          string branch,
          Option!string installScriptPath)
    in {
      assert(p_host != "null");
      assert(author != "null");
      assert(name != "null");
      assert(localPath != "null");
      assert(treeReference != "null");
      assert(branch != "null");
    } 
    do {
      this.p_host = host;
      this.p_author = author;
      this.p_name = name;
      this.p_localPath = localPath;
      this.p_refType = treeReferenceType;
      this.p_treeReference = treeReference;
      this.p_branch = branch;
      this.p_installScriptPath = installScriptPath;
    }

    /** Return the host. */
    string host() const { return p_host; }
    /** Return the author. */
    string author() const { return p_author; }
    /** Return the name. */
    string name() const { return p_name; }
    /** Return the local path. */
    string localPath() const { return p_localPath; }
    /** Return the tree reference type. */
    TreeReferenceType refType() const { return p_refType; }
    /** Return the tree reference. */
    string treeReference() const { return p_treeReference; }
    /** Return the branch. */
    string branch() const { return p_branch; }
    /** Return the install script path. */
    const(Option!string) installScriptPath() const { return p_installScriptPath; }

    override size_t toHash() const @safe pure nothrow
    {
      return p_host.hashOf(p_author.hashOf(p_name.hashOf(p_localPath.hashOf())));
    }

    override bool opEquals(const Object other) const
    {
      if (LocalRepository o = cast(LocalRepository) other) {
        return p_host == o.p_host 
            && p_author == o.p_author 
            && p_name == o.p_name 
            && p_localPath == o.p_localPath;
      } else {
        return false;
      }
    }
}

unittest {
  new LocalRepository("foo", "bar", "foobar", "barfoo", TreeReferenceType.COMMIT, "4f942", "" , Option!string.none());
  new LocalRepository("foo", "bar", "foobar", "barfoo", TreeReferenceType.COMMIT, "latest", "master", Option!string.none());
  new LocalRepository("foo", "bar", "foobar", "barfoo", TreeReferenceType.TAG, "latest", "", Option!string.none());
  // new LocalRepository("foo", "bar", "foobar", "barfoo", TreeReferenceType.TAG, "latest on branch1", ""); // Not valid, cannot specify branch with latest
}
