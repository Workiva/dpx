import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:dpx/src/args.dart';
import 'package:dpx/src/ensure_process_exit.dart';
import 'package:dpx/src/exit_exception.dart';
import 'package:dpx/src/find_reusable_package.dart';
import 'package:dpx/src/global_activate_package.dart';
import 'package:dpx/src/package_spec.dart';
import 'package:dpx/src/package_spec_exception.dart';
import 'package:dpx/src/prompt.dart';
import 'package:io/io.dart';

void main(List<String> args) async {
  final stopwatch = Stopwatch()..start();
  var logger = Logger.standard();

  try {
    final dpxArgs = parseDpxArgs(args);
    if (dpxArgs.verbose) {
      logger = Logger.verbose();
    }

    PackageSpec spec;
    try {
      spec = PackageSpec.parse(dpxArgs.packageSpec);
    } on PackageSpecException catch (error, stack) {
      throw ExitException(ExitCode.usage.code, '$error\n${usage()}', stack);
    }
    logger.trace('Parsed package spec "${dpxArgs.packageSpec}" into $spec');

    // Check if package is already installed at a suitable version/ref.
    logger
        .trace('Checking if suitable package is already installed globally...');
    String? packageName;
    var needsInstall = true;
    final reusablePackage = await findReusablePackage(spec, logger: logger);
    if (reusablePackage != null) {
      packageName = reusablePackage;
      needsInstall = false;
    }

    // Globally install package if needed.
    if (needsInstall) {
      logger
        ..stdout('Need to install the following packages:')
        ..stdout(spec.description);
      if (stdin.hasTerminal && !dpxArgs.autoInstall) {
        stdout.write('Ok to proceed? (y/n) ');
        final response = prompt('yn', 'n');
        if (response != 'y') {
          throw ExitException(ExitCode.usage.code, 'Canceled.');
        }
      }
      final activatedPackageName =
          await globalActivatePackage(spec, logger: logger);
      packageName ??= activatedPackageName;
    }

    // Finalize the command to run.
    String executable;
    List<String> executableArgs;
    String? packageExecutable;

    // If the executable was given explicitly, use it.
    if (dpxArgs.executable != null) {
      executable = dpxArgs.executable!;
      executableArgs = dpxArgs.restArgs;
    } else {
      // Otherwise, we'll use `dart pub global run` to run a package executable.
      executable = 'dart';

      // Note: this requires that we know the package name.
      if (packageName == null) {
        throw ExitException(
          ExitCode.software.code,
          'Could not infer package name, which is needed to run its executables.',
        );
      }

      // If the package spec included a package executable, use that, otherwise
      // omit that part and let Dart run the package's default executable.
      packageExecutable = spec.packageExecutable != null
          ? '$packageName:${spec.packageExecutable}'
          : packageName;

      executableArgs = [
        'pub',
        'global',
        'run',
        packageExecutable,
        ...dpxArgs.restArgs,
      ];
    }

    // Log how long DPX took before handing off to the actual command.
    final dpxTime =
        (stopwatch.elapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
    stopwatch.stop();
    logger.trace('Took ${dpxTime}s to start command.');

    // Run the command.
    logger.trace('SUBPROCESS: $executable ${executableArgs.join(' ')}');
    try {
      final process = await Process.start(
        executable,
        executableArgs,
        mode: ProcessStartMode.inheritStdio,
      );
      ensureProcessExit(process);
      final dpxExitCode = await process.exitCode;
      if (packageExecutable != null &&
          [ExitCode.data.code /* 65 */, ExitCode.noInput.code /* 66 */]
              .contains(dpxExitCode)) {
        // `dart pub global run <cmd>` exits with code 65 when the package for
        // the given <cmd> is not active or code 66 when the file cannot be
        // found within the package's `bin/`.
        // These are both equivalent to "command not found".
        throw ExitException(127, 'dpx: $packageExecutable: command not found');
      }
      exit(dpxExitCode);
    } on ProcessException catch (error) {
      if (error.message.contains('No such file')) {
        throw ExitException(127, 'dpx: $executable: command not found');
      } else {
        // Otherwise, the command was found but could not be executed.
        throw ExitException(126, 'dpx: $packageExecutable: ${error.message}');
      }
    }
  } on ExitException catch (error, stack) {
    logger.stderr(error.message);
    if (logger.isVerbose) {
      logger.stderr((error.stackTrace ?? stack).toString());
    }
    exit(error.exitCode);
  } catch (error, stack) {
    logger.stderr('Unexpected uncaught exception:\n$error\n$stack');
    exit(ExitCode.software.code);
  }
}
