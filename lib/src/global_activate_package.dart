import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:dpx/src/package_spec.dart';
import 'package:io/io.dart';

import 'exit_exception.dart';

/// Runs `dart pub global activate ...` to globally activate the package defined
/// by [spec] and returns the name of the activated package.
///
/// Throws if the activation command fails.
Future<String> globalActivatePackage(PackageSpec spec, {Logger? logger}) async {
  final args = ['pub', 'global', 'activate', ...spec.pubGlobalActivateArgs];
  final process = await Process.start('dart', args, runInShell: true);

  final results = await Future.wait([
    process.exitCode,
    process.stdout.transform(const SystemEncoding().decoder).join(),
    process.stderr.transform(const SystemEncoding().decoder).join(),
  ]);

  final exitCode = results[0] as int;
  final stdout = results[1] as String;
  final stderr = results[2] as String;
  logger?.trace('''
CMD: dart ${args.join(' ')}
STDOUT:
$stdout
STDERR:
$stderr
''');
  if (exitCode != ExitCode.success.code) {
    throw ExitException(
        exitCode, 'Failed to activate package globally: ${spec.description}');
  }

  final packageNamePattern =
      RegExp(r'^Activated (?<name>\w+) ', multiLine: true);
  final packageName = packageNamePattern.firstMatch(stdout)?.namedGroup('name');
  if (packageName == null) {
    throw ExitException(ExitCode.software.code,
        'Failed to parse package name from global activation output.');
  }
  return packageName;
}
