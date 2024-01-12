import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:dpx/src/exit_exception.dart';
import 'package:io/io.dart';

/// Runs `git ls-remote <gitUrl> <gitRef>` and parses the result to get the
/// latest resolved ref (commit sha) for the given git ref.
Future<String> resolveLatestGitRef(String gitUrl, String gitRef,
    {Logger? logger}) async {
  final args = ['ls-remote', gitUrl, gitRef];
  final process = await Process.start('git', args);

  final results = await Future.wait([
    process.exitCode,
    process.stdout.transform(const SystemEncoding().decoder).join(),
    process.stderr.transform(const SystemEncoding().decoder).join(),
  ]);

  final exitCode = results[0] as int;
  final stdout = results[1] as String;
  final stderr = results[2] as String;
  logger?.trace('''
CMD: git ${args.join(' ')}
STDOUT:
$stdout
STDERR:
$stderr
''');
  if (exitCode != ExitCode.success.code) {
    throw ExitException(
        exitCode, 'Failed to resolve git ref: $gitUrl at $gitRef');
  }

  final resolvedRefPattern = RegExp(r'^(?<sha>\w+)\s\w+', multiLine: true);
  final resolvedRef = resolvedRefPattern.firstMatch(stdout)?.namedGroup('sha');
  if (resolvedRef != null) {
    return resolvedRef;
  } else {
    throw ExitException(ExitCode.software.code,
        'Failed to parse resolved ref from output: "$stdout"');
  }
}
