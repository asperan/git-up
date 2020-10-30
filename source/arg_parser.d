module arg_parser;

/** Option represent a command line argument for the command 
    which modifies the behaviour of the application itself.
    The Option specification has no consciusness of the 
    passed argument: it just describes how to call it and
    what it does.
*/
struct Option {
  private:
    string p_shortVersion;
    string p_longVersion;
    string p_description;

    bool p_isLone;
    bool p_needArgument;

  public:
    /**
     * Create a new Option by specifying a short version, 
     * a long version (with two '-'), a description and, 
     * optionally, an argument for the option
     */
    this(string shortVersion, 
         string longVersion, 
         string description, 
         bool needArgument = true, 
         bool isLone = false) 
    {
        p_shortVersion = shortVersion;
        p_longVersion = longVersion;
        p_description = description;
        p_needArgument = needArgument;
        p_isLone = isLone;
    }

    /** Return the short version of the option. */
    @property string shortVersion() const { return p_shortVersion; }
    /** Return the long version of the option. */
    @property string longVersion()  const { return p_longVersion; }
    /** Return the description of the option, 
        it scan be displayed in the help panel. */
    @property string description()  const { return p_description; }
    /** Return whether the option needs to be followed by an argument. */
    @property bool   needArgument() const { return p_needArgument; }
    /** Return whether the argument must be used alone. 
        If yes, the first argument of this type has the 
        precedence and overwrite the behavior. */
    @property bool   isLone()       const { return p_isLone; }

    bool opEquals(string)(const string other) const
    {
        return other == p_shortVersion || other == p_longVersion;
    }

    size_t toHash() const @safe pure nothrow
    {
        return p_isLone.hashOf(
                p_needArgument.hashOf(
                 p_description.hashOf(
                  p_longVersion.hashOf(
                   p_shortVersion.hashOf()))));
    }
}

/**
 *  The options array contains all 
 *  the available options for git-update.
 */
immutable(immutable(Option)[]) options = [
  Option("-h", "--help", "Show help panel and exit.", false, true),
  Option("-v", "--version", "Show program version and exit.", false, true)
];

/+
    /** If optionArgument is an empty string,
     *  the option do not need an argument
     */
    private string optionArgument;
+/
unittest {
  const Option o = Option("-h", "--help", "Shows help panel");
  assert(o == "-h");
  assert(o == "--help");
  assert(o != "-g");
  assert(o == options[0]);
  assert(!options[0].needArgument);
}

/**
 * The RuntimeOption 
 */
struct RuntimeOption {

  private:
    immutable(Option*) p_option;
    const string p_optionArgument;

  public:
    /**
     * Creates a new runtime option with reference to an Option 
     * as parent and the argument, if needed.
     */
    this(immutable(Option*) option, string optionArgument = "")
    in
    {
      assert((*option).needArgument == (optionArgument.length > 0), 
             "Not needed argument passed to RuntimeOption of " ~ (*option).longVersion);
    }
    do
    {
      p_option = option;
      p_optionArgument = optionArgument;
    }

    /** Return a pointer to its parent Option. */
    @property immutable(Option*) option() immutable { return p_option; }
    /** Return a pointer to the argument for the option. */
    @property string optionArgument() const pure  { return p_optionArgument; }

    bool opEquals(Option)(const Option other) const
    {
        return other == *p_option;
    }

    size_t toHash() const @safe pure nothrow
    {
        return p_optionArgument.hashOf((*p_option).hashOf());
    }

}

private immutable(Option*) searchOption(string option) {
  for (int i = 0; i < options.length; i++) {
    if (options[i] == option) {
      return &options[i];
    }
  }
  return null;
}

/**
    Parses the input argument list and divides it into the main argument, 
    if present, and the potential options.
*/
void parseArguments(in string[] args, out string mainArg, out RuntimeOption[] activeOptions) {
  for (int i = 0; i < args.length; i++) {
    if (args[i][0..1] == "-" || args[i][0..2] == "--") {
      immutable(Option*) opt = searchOption(args[i]);
      if (opt != null) {
        if (opt.needArgument) {
          /** args.length will never be less or equal to 0, 
              as in that case the outer for is never entered.
              So in the following assertion there is no problem
              related to subtracting 1 to an unsigned value.
          */
          assert(i < (args.length - 1), "Last option required an argument, but argument list has finished.");
          string extraArgument = args[i+1];
          activeOptions ~= [RuntimeOption(opt, extraArgument)];
          i++;
        } else {
          activeOptions ~= [RuntimeOption(opt)];
        }
      }
    } else {
      /** Only the first main argument is parsed.
          Subsequent arguments will be ignored.
      */
      if (mainArg == null) {        
        mainArg = args[i];
      }
    }
  }
}

unittest {
  string[] args = ["--help", "file"];
  string mainArgument;
  RuntimeOption[] runtimeOptions;
  parseArguments(args, mainArgument, runtimeOptions);
  assert(mainArgument == "file");
  assert(runtimeOptions.length == 1);
}