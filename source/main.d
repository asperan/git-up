module main;

import print_help;
import apply;
import arg_parser;

int main(string[] args) {
  args = args[1..$];
  if (args.length <= 0) {
    print_help.helpMessage("Error: No operation or lone option has been specified.");
    return 1;
  } else {
    string mod = args[0];
    switch (mod) {
      case "apply":
        apply.apply("./Gitfile");
        break;
      case "-v":
      case "--version":
        print_help.versionMessage();
        break;
      default:
        print_help.helpMessage("Error: Operation '" ~ mod ~ "' not recognized.");
        return 1;
    }
  }
  return 0;
}
