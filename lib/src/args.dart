import 'dart:io';

import 'package:args/args.dart';
import 'package:dpx/src/exit_exception.dart';
import 'package:dpx/src/version.dart';
import 'package:io/io.dart';

final argParser = ArgParser(allowTrailingOptions: false)
  ..addFlag('help', abbr: 'h', negatable: false)
  ..addFlag('interactive', abbr: 'i', negatable: false, hide: true)
  ..addFlag('verbose', abbr: 'v', negatable: false)
  ..addFlag('version', negatable: false)
  ..addFlag('yes',
      abbr: 'y',
      negatable: false,
      help: 'Install missing packages without prompting.')
  ..addOption(
    'executable',
    abbr: 'e',
    help:
        'The executable to run. Overrides default behavior of using `dart pub global run ...`',
    valueHelp: 'executable',
  );

String usage() => '''Usage:
  dpx <package-spec> [args...]
  dpx <package-spec>:<package-executable> [args...]
  dpx <package-spec> -e <executable> [args...]

${argParser.usage}

<package-spec> supports named packages, custom pub servers, version constraints, and git sources with path and ref options. See readme for more info: https://github.com/Workiva/dpx#package-sources''';

class DpxArgs {
  // Flags
  final bool autoInstall;
  final bool verbose;

  // Options/args
  final String? executable;
  final String packageSpec;
  final List<String> restArgs;

  DpxArgs({
    required this.autoInstall,
    required this.executable,
    required this.packageSpec,
    required this.restArgs,
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

  if (parsedArgs['interactive'] == true) {
    stdout.write('Enter the package spec and any additional args:\n> ');
    final interactiveArgs = stdin.readLineSync()?.split(' ') ?? [];
    if ({'--interactive', '-i'}.intersection({...interactiveArgs}).isNotEmpty) {
      throw ExitException(ExitCode.usage.code,
          'Cannot use --interactive flag in interactive mode.');
    }
    return parseDpxArgs(interactiveArgs);
  }

  // A package spec must be specified as the first positional arg.
  if (parsedArgs.rest.isEmpty) {
    throw ExitException(
        ExitCode.usage.code, '''Must provide at least one positional arg.
${usage()}''');
  }

  return DpxArgs(
    autoInstall: parsedArgs['yes'] == true,
    executable: parsedArgs['executable'], // may be null
    packageSpec: parsedArgs.rest.first, // must be the first positional arg
    restArgs: parsedArgs.rest.skip(1).toList(),
    verbose: parsedArgs['verbose'] == true,
  );
}
