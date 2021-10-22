module main;

import configuration;
import utility.logging : printErrorHelpAndExit;
import operations : handleRemainingArgs;

void main(string[] args) {
  setExecutableName(args[0]);
  args = args[1..$];
  if (args.length <= 0) {
    printErrorHelpAndExit("No operation or option specified.");
  }
  string[] remainingArgs = parseCliArguments(args);
  if (remainingArgs.length <= 0) {
    printErrorHelpAndExit("No operation specified.");
  } else {
    handleRemainingArgs(remainingArgs);
  }
}

