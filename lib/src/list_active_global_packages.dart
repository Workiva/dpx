import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:dpx/src/get_system_cache_path.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'global_package.dart';

Iterable<GlobalPackage> listActiveGlobalPackages({
  Map<String, String>? environment,
  Logger? logger,
}) sync* {
  final pubCache = getSystemCachePath(environment: environment);
  final globalPackagesDir = Directory(p.join(pubCache, 'global_packages'));

  if (!globalPackagesDir.existsSync()) {
    logger?.trace(
        'No global packages found in system cache at "${globalPackagesDir.path}"');
    return;
  }

  for (final dir in globalPackagesDir
      .listSync(followLinks: false)
      .whereType<Directory>()) {
    final packageName = p.basename(dir.path);
    final pubspecLockFile = File(p.join(dir.path, 'pubspec.lock'));
    if (pubspecLockFile.existsSync()) {
      YamlMap pubspecLockYaml;
      try {
        pubspecLockYaml = loadYaml(pubspecLockFile.readAsStringSync());
      } catch (e) {
        logger
            ?.trace('Failed to read pubspec.lock at "${pubspecLockFile.path}"');
        continue;
      }

      try {
        final packages = pubspecLockYaml['packages'] ?? {};
        final package = packages[packageName] ?? {};
        final description = package['description'] ?? {};

        yield GlobalPackage(
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
        continue;
      }
    } else {
      logger?.trace('No pubspec.lock found at "${pubspecLockFile.path}"');
    }
  }
}
