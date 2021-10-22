module utility.parsing;

import utility.logging;

/**
 * Parses a YAML-compliant boolean literal into its bool value.
 */
bool parseBooleanLiteral(in string input, in string optionName) {
  import std.string : toLower;
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
      return printParsingErrorAndExit("Value '" ~ input ~  "' cannot be parsed into a boolean.", " @ option " ~ optionName );
  }
}

/** Parses a YAML-complient integer literal into its integer value. */
int parseIntegerLiteral(in string input, in string optionName) 
in(input.length > 0)
in(optionName.length > 0)
{
  import std.conv : to, ConvException;
  try {
    return input.to!int;
  } catch (ConvException e) {
    return printParsingErrorAndExit("Value '" ~ input ~ "' cannot be parsed into an integer.", " @ option " ~ optionName);
  }
}

/**
 * Returns: the absolute file path.
 */
string getFullFilePath(in string filePath) {
  import std.path : buildNormalizedPath, absolutePath, expandTilde;
  return filePath
           .expandTilde()
           .absolutePath()
           .buildNormalizedPath();
}

string toShortOrdinal(T)(T i) 
{
  import std.traits : isIntegral, isUnsigned;
  static assert(
    isIntegral!T && isUnsigned!T
  );
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

