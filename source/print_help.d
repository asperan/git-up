module print_help;

import std.stdio;
import arg_parser;

private immutable string VERSION = "0.1.0";

/** Prints help message.
    parameters:
    - message: message to display before the help message. 
               If empty nothing is displayed.
*/
void helpMessage(in string message = "") {
  if (message.length != 0) {
      writeln(message);
  }
  // TODO: prettify help string
  string helpString =
    `Usage: git-update <module> [path/to/Gitfile] [options]` ~ "\n" ~
    "\n" ~
    `Modules:` ~ "\n" ~
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