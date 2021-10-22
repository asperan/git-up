module operations;

public import operations.apply;

shared static this() {
  import std.functional : toDelegate;
  operationMap = [
    "apply": toDelegate(&apply),
  ];
}

/**
 * Handles the remaining arguments by using the first as the operation and the second as the operation own argument.
 */
void handleRemainingArgs(in string[] remainingArgs) {
  import utility.logging : printErrorHelpAndExit;
  auto selectedOperation = (remainingArgs[0] in operationMap);
  if (selectedOperation is null) {
    printErrorHelpAndExit("Operation '" ~ remainingArgs[0] ~ "' not supported.");
  } else {
    string operationArgument = "./Gitfile";
    if (remainingArgs.length >= 2) { operationArgument = remainingArgs[1]; }
    (*selectedOperation)(operationArgument);
  }
}

private __gshared immutable void delegate(string)[string] operationMap;

