module file_option;

import std.stdio;

import parsing_utils;

/** Type of the argument of a file option. */
enum ArgumentType {
  BOOL,
  INT,
  STRING
}

/**
    Argument holder for a file option.
    It can be a boolean, an integer or a string.
*/
private union FileOptionArgument {
  bool p_boolean;
  int p_integer;
  string p_str;
  /** Create a new boolean argument. */
  this(in bool boolean) {
    p_boolean = boolean;
  }
  /** Create a new integer argument. */
  this(in int integer) {
    p_integer = integer;
  }
  /** Create a new string argument. */
  this(in string str) {
    p_str = str;
  }
}

unittest {
  const FileOptionArgument arg = FileOptionArgument(true);
  assert(arg.p_boolean);
  const FileOptionArgument arg2 = FileOptionArgument("prova");
  assert(arg2.p_str == "prova");
}

/** 
    FileOption is an option for an operation known at compile time.
    It includes a name and an argument type, as they are known.
*/
struct FileOption {
  private:
    string name;
    ArgumentType argType;
  
    this(in string name, in ArgumentType argType)
    in(name != null && name != "")
    {
      this.name = name;
      this.argType = argType;
    }

    bool opEquals(FileOption)(const FileOption other) const
    {
      return this.name == other.name;
    }

    bool opEquals(const string other) const
    {
      return this.name == other;
    }

    size_t toHash() const @safe pure nothrow
    {
      return name.hashOf();
    }
}

unittest {
  const FileOption fo = FileOption("prova", ArgumentType.BOOL);
  assert(fo.name == "prova" && fo.argType == ArgumentType.BOOL);
}

/** Array with all the available FileOptions. */
shared immutable(immutable(FileOption)[]) fileOptions = [
  FileOption("updateOnly", ArgumentType.BOOL),
  FileOption("forceInstall", ArgumentType.BOOL)
];

unittest {
  assert(FileOption("updateOnly", ArgumentType.INT) == fileOptions[0]);
}

/** FileOption at runtime. it also has an argument of the specified type. */
class RuntimeFileOption : NamedParsable {
  private:
    immutable(FileOption*) fileOption;
    immutable(FileOptionArgument) argument;

  public:
    /** Creates a new RuntimeFileOption with an integer argument. */
    this(in immutable(FileOption*) fileOption, in immutable(int) argument) 
    in(fileOption!=null)
    in(fileOption.argType==ArgumentType.INT)
    {
      this.fileOption = fileOption;
      this.argument = FileOptionArgument(argument);
    }
    /** Creates a new RuntimeFileOption with a boolean argument. */
    this(in immutable(FileOption*) fileOption, in immutable(bool) argument) 
    in(fileOption!=null)
    in(fileOption.argType==ArgumentType.BOOL)
    {
      this.fileOption = fileOption;
      this.argument = FileOptionArgument(argument);
    }
    /** Creates a new RuntimeFileOption with a string argument. */
    this(in immutable(FileOption*) fileOption, in immutable(string) argument) 
    in(fileOption!=null)
    in(fileOption.argType==ArgumentType.STRING)
    {
      this.fileOption = fileOption;
      this.argument = FileOptionArgument(argument);
    }
    /** Returns the FileOption name. */
    string name() const { return fileOption.name; }
    /** Returns the FileOption argument type. */
    ArgumentType type() const { return fileOption.argType; }
    /** Returns the boolean argument, if it has the correct type. */
    bool argBool() const in(fileOption.argType == ArgumentType.BOOL) { return argument.p_boolean; }
    /** Returns the integer argument, if it has the correct type. */
    int argInt() const in(fileOption.argType == ArgumentType.INT) { return argument.p_integer; }
    /** Returns the string argument, if it has the correct type. */
    string argString() const in(fileOption.argType == ArgumentType.STRING) { return argument.p_str; }
}

immutable(FileOption*) searchFileOption(in string name) {
  for (int i = 0; i < fileOptions.length; i++) {
    if (fileOptions[i] == name) {
      return &fileOptions[i];
    }
  }
  printParsingErrorAndExit("Option " ~ name ~ " not recognized.");
  return null;
}
