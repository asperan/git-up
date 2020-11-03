module parsing_utils;

import std.stdio;
import core.stdc.stdlib;
import std.string;
import std.file;


void printParsingErrorAndExit(in string errorMessage, in string additionalInfo = "") {
  stderr.writeln("Parsing error" ~ additionalInfo ~ ": " ~ errorMessage);
  exit(1);
}

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

string parseFilePath(in string filePath) {
  if (filePath[0..1] == "/") { // Absolute path, no transformation needed
    return filePath;
  } else { // Relative path, prepend the current directory
    return getcwd() ~ "/" ~ filePath;
  }
}