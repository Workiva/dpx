import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:dpx/src/get_system_cache_path.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'global_package.dart';

GlobalPackage? findActiveGlobalPackage(
  String packageName, {
  Map<String, String>? environment,
  Logger? logger,
}) {
  final pubCache = getSystemCachePath(environment: environment);
  final globalPackageDir =
      Directory(p.join(pubCache, 'global_packages', packageName));

  if (!globalPackageDir.existsSync()) {
    logger?.trace(
        'No global package found in system cache at "${globalPackageDir.path}"');
    return null;
  }

  final pubspecLockFile = File(p.join(globalPackageDir.path, 'pubspec.lock'));
  if (pubspecLockFile.existsSync()) {
    YamlMap pubspecLockYaml;
    try {
      pubspecLockYaml = loadYaml(pubspecLockFile.readAsStringSync());
    } catch (e) {
      logger?.trace('Failed to read pubspec.lock at "${pubspecLockFile.path}"');
      return null;
    }

    try {
      final packages = pubspecLockYaml['packages'] ?? {};
      final package = packages[packageName] ?? {};
      final description = package['description'] ?? {};

      return GlobalPackage(
        packageName,
        package['source'],
        Version.parse(package['version'] ?? ''),
        url: description['url'],
        path: description['path'],
        resolvedRef: description['resolved-ref'],
      );
    } catch (error, stack) {
      logger?.trace('''
Unexpected error reading pubspec.lock as YAML:
$error
$stack
''');
      return null;
    }
  } else {
    logger?.trace('No pubspec.lock found at "${pubspecLockFile.path}"');
    return null;
  }
}
