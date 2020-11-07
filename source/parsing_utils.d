module parsing_utils;

import std.stdio;
import core.stdc.stdlib;
import std.string;
import std.file;
import std.path;

/**
    Prints an error, with optional additional information and exit the program with an error state.
*/
void printParsingErrorAndExit(in string errorMessage, in string additionalInfo = "") {
  stderr.writeln("Parsing error" ~ additionalInfo ~ ": " ~ errorMessage);
  exit(1);
}

/**
    Parses a YAML-compliant boolean literal into its bool value.
*/
bool parseBooleanLiteral(in string input, in string optionName) {
  switch (input.toLower()) {
    case "y":
    case "yes":
    case "true":
    case "on":
      return true;
    case "n":
    case "no":
    case "false":
    case "off":
      return false;
    default:
      printParsingErrorAndExit("Value '" ~ input ~  "' cannot be parsed into a boolean.", " @ option " ~ optionName );
      assert(0);
  }
}

/** Parses a YAML-complient integer literal into its integer value. */
int parseIntegerLiteral(in string input, in string optionName) 
in(input.length > 0)
in(optionName.length > 0)
{
  import std.conv : to;
  return input.to!int;
}

unittest {
  assert("100".parseIntegerLiteral("unittest") == 100);
  //assert("42e10".parseIntegerLiteral("unittest") == 42); // Error, 42e10 is not recognized as an integer
}

/**
    Manages file paths to transform the into absolute paths.
    If the path is already absolute, nothing is changed;
    else the current working directory is prepended to the provided path.
*/
string parseFilePath(in string filePath) {
  if (filePath[0..1] == dirSeparator) { // Absolute path, no transformation needed
    return filePath;
  } else { // Relative path, prepend the current directory
    return getcwd() ~ dirSeparator ~ filePath;
  }
}

/** Parsable element with a name. */
interface NamedParsable
{
  /** Returns the name of the parsable object. */
  string fullName();
}