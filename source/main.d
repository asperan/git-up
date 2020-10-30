module main;

import print_help;
import apply;
import arg_parser;

void main(string[] args) {
    args = args[1..$];
    if (args.length <= 0) {
        print_help.printHelp("Error: No module has been specified.");
    } else {
        string mod = args[0];
        switch (mod) {
            case "apply":
                apply.apply("./Gitfile");
                break;
            default:
                print_help.printHelp("Error: Module '" ~ mod ~ "' not recognized.");
                break;
        }
    }
}
