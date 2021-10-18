module utility.parsing;

import utility.logging;

/**
    Parses a YAML-compliant boolean literal into its bool value.
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


