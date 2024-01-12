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

  try {
    final dpxArgs = parseDpxArgs(args);
    final logger = dpxArgs.verbose ? Logger.verbose() : Logger.standard();

    PackageSpec spec;
    try {
      spec = PackageSpec.parse(dpxArgs.packageSpec);
    } on PackageSpecException catch (error) {
      throw ExitException(ExitCode.usage.code, '$error\n${usage()}');
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
      if (!dpxArgs.autoInstall) {
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
    String? command = dpxArgs.command;
    if (command == null || command.startsWith(':')) {
      if (packageName == null) {
        throw ExitException(ExitCode.software.code,
            'Could not infer package name to use as default command.');
      }

      if (command == null) {
        // If command was not explicitly given, default to the package name.
        command = packageName;
      } else {
        // If command starts with `:`, it's shorthand that omits the package name.
        // Example: dpx --package=build_runner :graph_inspector --> dart pub global run build_runner:graph_inspector
        command = '$packageName$command';
      }
    }

    // Log how long DPX took before handing off to the actual command.
    final dpxTime =
        (stopwatch.elapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
    stopwatch.stop();
    logger.trace('Took ${dpxTime}s to start command.');

    // First, try to run the command directly, assuming that it's in the PATH.
    logger.trace('SUBPROCESS: $command ${dpxArgs.commandArgs.join(' ')}');
    try {
      final process = await Process.start(
        command,
        dpxArgs.commandArgs,
        mode: ProcessStartMode.inheritStdio,
      );
      ensureProcessExit(process);
      exit(await process.exitCode);
    } on ProcessException catch (error) {
      if (error.message.contains('No such file')) {
        // If the command was not found, it may only be available within the
        // package's `bin/`. Fallback to `dart pub global run`.
        logger.trace('Command not found, trying `dart pub global run`');
        final fallbackArgs = [
          'pub',
          'global',
          'run',
          command,
          ...dpxArgs.commandArgs,
        ];
        logger.trace('SUBPROCESS: dart ${fallbackArgs.join(' ')}');
        final process = await Process.start(
          'dart',
          fallbackArgs,
          mode: ProcessStartMode.inheritStdio,
        );
        ensureProcessExit(process);
        final dpgrCode = await process.exitCode;
        if ([ExitCode.data.code /* 65 */, ExitCode.noInput.code /* 66 */]
            .contains(dpgrCode)) {
          // `dart pub global run <cmd>` exits with code 65 when the package for
          // the given <cmd> is not active or code 66 when the file cannot be
          // found within the package's `bin/`.
          // These are both equivalent to "command not found".
          throw ExitException(127, 'dpx: $command: command not found');
        }
        exit(await process.exitCode);
      } else {
        // Otherwise, the command was found but could not be executed.
        throw ExitException(126, 'dpx: $command: ${error.message}');
      }
    }
  } on ExitException catch (error) {
    print(error.message);
    exit(error.exitCode);
  } catch (error, stack) {
    print('Unexpected uncaught exception:\n$error\n$stack');
    exit(ExitCode.software.code);
  }
}
