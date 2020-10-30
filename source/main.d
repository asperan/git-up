module main;

import std.stdio;
import apply;
import arg_parser;

void main(string[] args) {
    args = args[1..$];
    if (args.length <= 0) {
        printHelp("Error: No module has been specified.");
    } else {
        string mod = args[0];
        switch (mod) {
            case "apply":
                apply.apply("./Gitfile");
                break;
            default:
                printHelp("Error: Module '" ~ mod ~ "' not recognized.");
                break;
        }
    }
}

/** Prints help message.
    parameters:
    - message: message to display before the help message. 
               If empty nothing is displayed.
*/
private void printHelp(string message = "") {
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