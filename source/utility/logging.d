module utility.logging;

import core.stdc.stdlib : exit;

import configuration;

/**
 * Prints the given error message and exit the program with an exit status 1.
 * Params:
 *   errorMessage = the message to display.
 */
noreturn printErrorHelpAndExit(in string errorMessage) {
  import core.stdc.stdlib : exit;
  import std.stdio : writeln;
  writeln("Error: " ~ errorMessage);
  writeln(getHelpMessage());
  return exit(1);
}

/**
 * Prints an error, with optional additional information and exit the program with an error state.
 */
noreturn printParsingErrorAndExit(in string errorMessage, in string additionalInfo = "") {
  import std.stdio : stderr;
  stderr.writeln("Parsing error" ~ additionalInfo ~ ": " ~ errorMessage);
  return exit(1);
}

/**
 * Prints an execution error message occured during an operation and exit with an error state.
 */
void printExecutionError(in string operation, in string errorMessage) {
  import std.stdio : stderr;
  stderr.writeln("Execution error for " ~ operation ~ ": " ~ errorMessage);
  exit(1);
}

/**
 * If the verbose output is enabled, prints the message.
 */
pragma(inline, true):
void printVerbose(in string message) {
  if (Configuration.getInstance.isVerbose) {
    import std.stdio : writefln;
    writefln(message);
  }
}

/**
 * Returns: the NULL device of the system.
 */
pragma(inline, true):
string getNullDevice() {
  version(linux) { return "/dev/null"; }
  version(Windows) { return "NUL"; }
}

