module configuration;

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

  private bool verbose;

  private this() { 
    verbose = false;
  }

  /**
   * Returns: whether the flag 'verbose' is on.
   */
  public bool isVerbose() { return this.verbose; }

  private void setVerbose(bool on) {
    this.verbose = on;
  }
}

/**
 * Parse the CLI arguments with the internal parser.
 * Returns: the list of the unrecognized options.
 */
string[] parseCliArguments(string[] args) {
  return cliOptionParser.parse(args);
}

/**
 * Prints the given error message and exit the program with an exit status 1.
 * Params:
 *   errorMessage = the message to display.
 */
void printErrorHelpAndExit(in string errorMessage) {
  import core.stdc.stdlib : exit;
  import std.stdio : writeln;
  writeln("Error: " ~ errorMessage);
  printHelpMessage();
  exit(1);
}

/**
 * Set the executable name. It should be used only at the start of the program (i.e. the first lines of the main function).
 * Params:
 *   execName = the executable name.
 */
void setExecutableName(in string execName) {
  executableName = execName;
}

private string executableName = "";

private __gshared CommandLineOptionParser cliOptionParser = 
  new SimpleOptionParserBuilder()
  .addOption("-h", "--help", "Print help message and exit.", () { printHelpMessage(); })
  .addOption("-v", "--version", "Print version number and exit.", () { printVersionMessage(); })
  .addOption("-w", "--verbose", "Verbose output.", () { Configuration.getInstance.setVerbose(true); })
	.build();

private void printHelpMessage() {
  import std.path : baseName;
  string usageString = "Usage: " ~ baseName(executableName) ~ " [options] <sub-command>" ~ "\n";
  string subcommandsString = "" ~ "\n";
  string cliOptionsString = "Options:" ~ "\n" ~ getSimpleHelpMessage(cliOptionParser);

  import std.stdio : writeln;
  writeln(usageString ~ "\n" ~ subcommandsString ~ "\n" ~ cliOptionsString);
}

private string VERSION = "v1.2.0";

private void printVersionMessage() {
  import std.stdio : writeln;
  writeln("Version: " ~ VERSION);
}
