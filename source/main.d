module main;

import std.stdio;
import apply;

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

void printHelp(string message = "") {
    if (message.length != 0) {
        writeln(message);
    }
    writeln(
    `Usage: git-update <module> [path/to/Gitfile] [options]`, "\n",
    "\n",
    `Modules:`, "\n",
    `  - apply => applies the gitfile configuration of repositories`, "\n",
    "\n",
    `Options:`, "\n",
    `  No option are available yet.`
    );
}