module main;

import print_help;
import apply;
import arg_parser;
import core.stdc.stdlib;

int main(string[] args) {
  args = args[1..$];
  if (args.length <= 0) {
    print_help.helpMessage("Error: No operation or lone option has been specified.");
    return 1;
  } else {
    string operation;
    string mainArgument;
    RuntimeOption[] options;
    arg_parser.parseArguments(args, operation, mainArgument, options);
    checkLoneOptions(options);
    RuntimeConfiguration.loadConfiguration(options);
    switch (operation) {
      case "apply":
        apply.apply(mainArgument);
        break;
      default:
        print_help.helpMessage("Error: Operation '" ~ operation ~ "' not recognized.");
        exit(1);
    }
  }
  return 0;
}

private void checkLoneOptions(in RuntimeOption[] options) {
  foreach (option; options)
  {
    if (option.option.isLone) {
      handleLoneOption(option);
    }
  }
}

private void handleLoneOption(in RuntimeOption option) {
  final switch(option.option.shortVersion) {
    case "-h":
      print_help.helpMessage();
      exit(0);
      break;
    case "-v":
      print_help.versionMessage();
      exit(0);
      break;
  }
}