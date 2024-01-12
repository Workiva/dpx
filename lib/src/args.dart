import 'package:args/args.dart';
import 'package:dpx/src/exit_exception.dart';
import 'package:dpx/src/version.dart';
import 'package:io/io.dart';

final argParser = ArgParser(allowTrailingOptions: false)
  ..addFlag('help', abbr: 'h', negatable: false)
  ..addFlag('verbose', abbr: 'v', negatable: false)
  ..addFlag('version', negatable: false)
  ..addFlag('yes',
      abbr: 'y',
      negatable: false,
      help: 'Install missing packages without prompting.')
  ..addOption(
    'package',
    abbr: 'p',
    help:
        'The package to install. Supports named packages, custom pub servers, version constraints, and git repos with path and ref options.',
    valueHelp: 'package-spec',
  );

String usage() => '''Usage:
  dpx <package-spec> [args...]
  dpx --package=<package-spec> <cmd> [args...]

${argParser.usage}

<package-spec> supports custom pub servers and git sources. See readme for more info: https://github.com/Workiva/dpx#package-sources''';

class DpxArgs {
  // Flags
  final bool autoInstall;
  final bool verbose;

  // Options/args
  final String? command;
  final List<String> commandArgs;
  final String packageSpec;

  DpxArgs({
    required this.autoInstall,
    required this.command,
    required this.commandArgs,
    required this.packageSpec,
    required this.verbose,
  });
}

DpxArgs parseDpxArgs(List<String> args) {
  ArgResults parsedArgs;
  try {
    parsedArgs = argParser.parse(args);
  } on ArgParserException catch (error) {
    throw ExitException(ExitCode.usage.code, '$error\n${usage()}');
  }

  if (parsedArgs['help'] == true) {
    throw ExitException(ExitCode.success.code, usage());
  }
  if (parsedArgs['version'] == true) {
    throw ExitException(ExitCode.success.code, packageVersion);
  }

  // Either a package spec or a command name must be specified as the first
  // positional arg.
  if (parsedArgs.rest.isEmpty) {
    throw ExitException(
        ExitCode.usage.code, '''Must provide at least one positional arg.
${usage()}''');
  }

  String? command;
  List<String> commandArgs;
  String packageSpec;
  if (!parsedArgs.wasParsed('package')) {
    // When `--package` or `-p` is no specified, then we treat the first
    // positional arg as both the package spec and the command to run. We do
    // this by assuming that the command to run is the same as the package's
    // name, which can be obtained from the package spec itself or from the
    // logs when globally activating the package.
    packageSpec = parsedArgs.rest.first;
    commandArgs = parsedArgs.rest.skip(1).toList();
  } else {
    // When `--package` or `-p` is specified, then we avoid inferring the
    // command to run from the package spec and instead require that the first
    // positional arg be the command.
    packageSpec = parsedArgs['package'];
    command = parsedArgs.rest.first;
    commandArgs = parsedArgs.rest.skip(1).toList();
  }

  return DpxArgs(
    autoInstall: parsedArgs['yes'] == true,
    command: command,
    commandArgs: commandArgs,
    packageSpec: packageSpec,
    verbose: parsedArgs['verbose'] == true,
  );
}
