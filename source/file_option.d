module file_option;

import std.stdio;

import parsing_utils;

// TODO: change FileOption argument with Algebraic!(int, bool, string)
// https://dlang.org/library/std/variant/algebraic.html

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
    string p_name;
    ArgumentType p_argType;
    FileOptionArgument defaultValue;

    this(in string name, in ArgumentType argType)
    in(name != null && name != "")
    {
      p_name = name;
      p_argType = argType;
    }

    this(in string name, in ArgumentType argType, in bool booleanArgument) 
    in(argType == ArgumentType.BOOL)
    {
      this(name, argType);
      defaultValue.p_boolean = booleanArgument;
    }

    this(in string name, in ArgumentType argType, in int integerArgument) 
    in(argType == ArgumentType.INT)
    {
      this(name, argType);
      defaultValue.p_integer = integerArgument;
    }

    this(in string name, in ArgumentType argType, in string stringArgument) 
    in(argType == ArgumentType.STRING)
    {
      this(name, argType);
      defaultValue.p_str = stringArgument;
    }

  public:
    /** Returns the name of the option. */
    string name() const { return p_name; }
    /** Returns the argument type. */
    ArgumentType argType() const { return p_argType; }

    /** Returns the default value, if it has the correct type. */
    bool defaultBool() const in(argType == ArgumentType.BOOL) { return defaultValue.p_boolean; }
    /** Returns the default value, if it has the correct type. */
    int defaultInt() const in(argType == ArgumentType.INT) { return defaultValue.p_integer; }
    /** Returns the default value, if it has the correct type. */
    string defaultString() const in(argType == ArgumentType.STRING) { return defaultValue.p_str; }

    bool opEquals(FileOption)(const FileOption other) const
    {
      return p_name == other.name;
    }

    bool opEquals(const string other) const
    {
      return p_name == other;
    }

    size_t toHash() const @safe pure nothrow
    {
      return p_name.hashOf();
    }

}

unittest {
  const FileOption fo = FileOption("prova", ArgumentType.BOOL);
  assert(fo.name == "prova" && fo.argType == ArgumentType.BOOL);
}

/** Array with all the available FileOptions. */
shared immutable(immutable(FileOption)[]) fileOptions = [
  /// If true, git repository to be clone will not be cloned.
  FileOption("updateOnly", ArgumentType.BOOL, false),
  /// If true, even if there are no changes, the install script (if present) will be run.
  FileOption("forceInstall", ArgumentType.BOOL, false),
  /// If true, the missing directory of an install path will be created before cloning the repository.
  FileOption("createMissingDirs", ArgumentType.BOOL, false)
];

unittest {
  assert(FileOption("updateOnly", ArgumentType.INT) == fileOptions[0]);
  assert(fileOptions[0].defaultBool() == false);
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
    string fullName() const { return fileOption.name; }
    alias name = fullName;
    /** Returns the FileOption argument type. */
    ArgumentType type() const { return fileOption.argType; }
    /** Returns the boolean argument, if it has the correct type. */
    bool argBool() const in(fileOption.argType == ArgumentType.BOOL) { return argument.p_boolean; }
    /** Returns the integer argument, if it has the correct type. */
    int argInt() const in(fileOption.argType == ArgumentType.INT) { return argument.p_integer; }
    /** Returns the string argument, if it has the correct type. */
    string argString() const in(fileOption.argType == ArgumentType.STRING) { return argument.p_str; }

    override bool opEquals(Object other) const
    {
      if (auto oOpt = cast(RuntimeFileOption) other) {
        return name() == oOpt.name();
      } else {
        return false;
      }
    }

    override size_t toHash() @safe nothrow const
    {
      return argument.hashOf(fileOption.hashOf());
    }

    bool opEquals(const string other) const
    {
      return name() == other;
    }
}

/** Searches an option by name in the array of all options. */
immutable(FileOption*) searchFileOption(in string name) {
  for (int i = 0; i < fileOptions.length; i++) {
    if (fileOptions[i] == name) {
      return &fileOptions[i];
    }
  }
  printParsingErrorAndExit("Option '" ~ name ~ "' not recognized.");
  return null;
}


unittest {
  RuntimeFileOption rfo = new RuntimeFileOption(&fileOptions[0], true);
  assert(rfo == rfo);
  assert(rfo == "updateOnly");
  assert(rfo.name() == rfo.fullName());
}

/** Return the value of a boolean runtime option if present in the passed array. The default value otherwise. */
bool searchBooleanOption(in string name, in RuntimeFileOption[] options) {
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

/** Return the value of an integer runtime option if present in the passed array. The default value otherwise. */
int searchIntegerOption(in string name, in RuntimeFileOption[] options) {
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

/** Return the value of a string runtime option if present in the passed array. The default value otherwise. */
string searchStringOption(in string name, in RuntimeFileOption[] options) {
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