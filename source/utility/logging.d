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
 * If the verbose output is enabled, prints the message.
 */
pragma(inline, true):
void printVerbose(in string message) {
  if (Configuration.getInstance.isVerbose()) {
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

/**
 * Converts an unsigned integer into the ordinal string representation.
 */
string toShortOrdinal(int i) 
in (i>0)
{
  import std.conv : to;
  if (i >= 11 && i <= 13) { // Special cases
    return i.to!string(10) ~ "th";
  } else {
    switch (i % 10) {
      case 1:
        return i.to!string(10) ~ "st";
      case 2:
        return i.to!string(10) ~ "nd";
      case 3:
        return i.to!string(10) ~ "rd";
      default:
        return i.to!string(10) ~ "th";
    }
  }
}

unittest {
  assert(1.toShortOrdinal() == "1st");
  assert(11.toShortOrdinal() == "11th");
  assert(22.toShortOrdinal() == "22nd");
}
