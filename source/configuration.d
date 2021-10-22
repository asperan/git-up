module configuration;

import std.typecons : Tuple;

import asperan.cli_args.simple_option_parser;

/**
 * Configuration singleton. It contains all the configurable options and flags.
 */
final class Configuration {
  private __gshared Configuration instance = new Configuration();

  /**
   * Returns: The singleton instance.
   */
  public static Configuration getInstance() {
    return instance;
  }

  // CLI options + flags
  private bool verbose;
  private bool quiet;

  // Gitfile options
  private bool updateOnly;
  private bool forceInstall;
  private bool createMissingDirs;

  private this() { 
    verbose = false;
    quiet = false;
    updateOnly = true;
    forceInstall = false;
    createMissingDirs = false;
  }

  /**
   * Returns: whether the flag 'verbose' is on.
   */
  public bool isVerbose() { return this.verbose; }
  /**
   * Returns: whether the flag 'quiet' is on.
   */
  public bool isQuiet() { return this.quiet; }

  public bool getUpdateOnly() { return this.updateOnly; }
  public void setUpdateOnly(bool on) { this.updateOnly = on; }

  public bool getForceInstall() { return this.forceInstall; }
  public void setForceInstall(bool on) { this.forceInstall = on; }

  public bool getCreateMissingDirs() { return this.createMissingDirs; }
  public void setCreateMissingDirs(bool on) { this.createMissingDirs = on; }

  private void setVerbose(bool on) { this.verbose = on; }

  private void setQuiet(bool on) { this.quiet = on; }
}

/**
 * Parse the CLI arguments with the internal parser.
 * Returns: the list of the unrecognized options.
 */
string[] parseCliArguments(string[] args) {
  return cliOptionParser.parse(args);
}

void parseGitfileOption(Tuple!(string, string) options) {
  gitfileOptionHandlers[options[0]](options[1]);
}

/**
 * Set the executable name. It should be used only at the start of the program (i.e. the first lines of the main function).
 * Params:
 *   execName = the executable name.
 */
void setExecutableName(in string execName) {
  executableName = execName;
}

string getHelpMessage() {
  import std.path : baseName;
  string usageString = "Usage: " ~ baseName(executableName) ~ " <[-h|-v]|<operation> [options]>" ~ "\n";
  string subcommandsString = "Operations:" ~ "\n" ~ getOperationHelpString;
  string cliOptionsString = "Options:" ~ "\n" ~ getSimpleHelpMessage(cliOptionParser);
  
  return usageString ~ "\n" ~ subcommandsString ~ "\n" ~ cliOptionsString;
}

private string executableName = "";

private __gshared CommandLineOptionParser cliOptionParser = 
  new SimpleOptionParserBuilder()
  .addOption("-h", "--help", "Print help message and exit.", () { printHelpMessage(); })
  .addOption("-v", "--version", "Print version number and exit.", () { printVersionMessage(); })
  .addOption("-w", "--verbose", "Verbose output.", () { Configuration.getInstance.setVerbose(true); })
  .addOption("-q", "--quiet", "Silent output. Prevail over verbose option.", () { Configuration.getInstance.setQuiet(true); })
	.build();

private __gshared immutable(void delegate(string)[string]) gitfileOptionHandlers;

shared static this() {
  import utility.parsing : parseBooleanLiteral;
  gitfileOptionHandlers = [
    "updateOnly": (s) { Configuration.getInstance.setUpdateOnly(parseBooleanLiteral(s, "updateOnly")); },
    "forceInstall": (s) { Configuration.getInstance.setForceInstall(parseBooleanLiteral(s, "forceInstall")); },
    "createMissingDirs": (s) { Configuration.getInstance.setCreateMissingDirs(parseBooleanLiteral(s, "createMissingDirs")); },
  ];
}

private string getOperationHelpString() {
  import std.algorithm.searching : maxElement;
  import std.algorithm.iteration : map, reduce;
  import std.string : leftJustify;
  string[string] operationHelpStrings = [
    "apply": "Apply the changes specified in the Gitfile.",
  ];
  size_t maxOperationLength = operationHelpStrings.keys.map!(k => k.length).maxElement;
  return operationHelpStrings.keys.map!(helpString => leftJustify(helpString, maxOperationLength) ~ "  " ~ operationHelpStrings[helpString] ~ "\n").reduce!"a ~ b";
}

private void printHelpMessage() {
  import std.stdio : writeln;
  import core.stdc.stdlib : exit;
  writeln(getHelpMessage());
  exit(0);
}

private string VERSION = "v1.1.1";

private void printVersionMessage() {
  import std.stdio : writeln;
  import core.stdc.stdlib : exit;
  writeln("Version: " ~ VERSION);
  exit(0);
}
