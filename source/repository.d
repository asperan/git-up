module repository;

import std.regex;
import parsing_utils;

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
class LocalRepository : NamedParsable {
  private:
    string host;
    string author;
    string p_name;

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
          string p_name, 
          string localPath, 
          TreeReferenceType treeReferenceType,
          string treeReference,
          string installScriptPath)
    in {
      assert(host != "null");
      assert(author != "null");
      assert(p_name != "null");
      assert(localPath != "null");
      assert(treeReference != "null");
      if (treeReferenceType == TreeReferenceType.COMMIT) {
        auto matchResult = treeReference.matchAll(commitRegex); // @suppress(dscanner.suspicious.unmodified)
        assert(matchResult.front.hit == treeReference);
      }
    } 
    do {
      this.host = host;
      this.author = author;
      this.p_name = p_name;
      this.localPath = localPath;
      this.refType = treeReferenceType;
      this.treeReference = treeReference;
      this.installScriptPath = installScriptPath;
    }

    /** Return the full name of the repository. */
    string name() const {
      string fullName = "Repository '";
      fullName ~= host ~ (host[host.length-1..host.length] == "/" ? "" : "/"); //@suppress(dscanner.suspicious.length_subtraction)
      fullName ~= author ~ "/";
      fullName ~= p_name ~ "'";
      return fullName;
    }

    override size_t toHash() const @safe pure nothrow
    {
      return host.hashOf(author.hashOf(p_name.hashOf(localPath.hashOf())));
    }

    override bool opEquals(const Object other) const
    {
      if (LocalRepository o = cast(LocalRepository) other) {
        return host == o.host 
            && author == o.author 
            && p_name == o.p_name 
            && localPath == o.localPath;
      } else {
        return false;
      }
    }
}

unittest {
  LocalRepository("foo", "bar", "foobar", "barfoo", TreeReferenceType.COMMIT, "4f942", "");
  LocalRepository("foo", "bar", "foobar", "barfoo", TreeReferenceType.COMMIT, "07a0", "");
}