module print_help;

import std.stdio;
import arg_parser;

private immutable string VERSION = "1.0.0";

/** Prints help message.
    parameters:
    - errorMessage: message to display before the help message. 
                    If empty nothing is displayed.
*/
void helpMessage(in string errorMessage = "") {
  if (errorMessage.length != 0) {
      writeln(errorMessage);
  }
  // TODO: prettify help string
  string helpString =
    `Usage: git-update <operation> [path/to/Gitfile] [options]` ~ "\n" ~
    "\n" ~
    `Operations:` ~ "\n" ~
    `  - apply => applies the gitfile configuration of repositories` ~ "\n" ~
    "\n";

  helpString ~=
    `Options:` ~ "\n"
  ;
  foreach (opt; arg_parser.options)
  {
    helpString ~= `  ` ~ opt.shortVersion ~ `, ` ~ opt.longVersion ~ `  ` ~ opt.description ~ "\n";
  }
  
  writeln(helpString);
}

/**
    Prints version message.
*/
void versionMessage() {
  writeln("Current version: ", VERSION);
}