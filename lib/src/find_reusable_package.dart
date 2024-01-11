import 'package:cli_util/cli_logging.dart';
import 'package:pub_semver/pub_semver.dart';

import 'find_active_global_package.dart';
import 'git_package_spec.dart';
import 'global_package.dart';
import 'list_active_global_packages.dart';
import 'package_spec.dart';
import 'pub_package_spec.dart';
import 'resolve_latest_git_ref.dart';

/// Attempts to find a package that is already globally installed and fits the
/// given [spec].
///
/// If found, returns the package's name.
/// If not found, returns null.
Future<String?> findReusablePackage(PackageSpec spec, {Logger? logger}) async {
  if (spec is PubPackageSpec) {
    // For pub-based package specs, we already have the package name, which
    // means we can look for a specific global package instead of scanning
    // through all of them.
    final globalPackage =
        findActiveGlobalPackage(spec.packageName, logger: logger);
    if (globalPackage != null) {
      var matches = true;
      // Global pkg must also be hosted
      matches &= globalPackage.source == 'hosted';
      // and from the same pub server
      matches &= globalPackage.url == (spec.pubServerUrl ?? 'https://pub.dev');
      // and at a version that satisfies the constraint
      if (spec.versionConstraint != null) {
        final constraint = VersionConstraint.parse(spec.versionConstraint!);
        matches &= constraint.allows(globalPackage.version);
      }

      if (matches) {
        logger?.trace(
            'Found package "${spec.packageName}" version "${globalPackage.version}" installed globally.');
        return spec.packageName;
      } else {
        logger?.trace(
            'Found $globalPackage, but it did not match spec: "${spec.description}"');
        return null;
      }
    }
  }

  if (spec is GitPackageSpec) {
    // For git-based package specs, we don't know the package name, so we scan
    // through all of the active global packages looking for one that matches
    // the URL and path.
    GlobalPackage? globalPackage;
    for (final gp in listActiveGlobalPackages(logger: logger)) {
      logger?.trace('Checking: $gp');
      // TODO: canonicalize git URLs when comparing
      if (gp.url == spec.gitUrl && gp.gitPath == (spec.gitPath ?? '.')) {
        globalPackage = gp;
        break;
      }
    }

    if (globalPackage != null) {
      // We have a matching package based on git URL and path, but now we need
      // to compare the resolved ref of the installed package to the latest
      // resolved ref from the git remote.
      logger?.trace('Resolving git ref...');
      final latestResolvedRef = await resolveLatestGitRef(
          spec.gitUrl, spec.gitRef ?? 'HEAD',
          logger: logger);
      logger?.trace('Resolving git ref done.');

      if (globalPackage.gitResolvedRef == latestResolvedRef) {
        logger?.trace(
            'Found package installed from "${globalPackage.url}" at ref "${globalPackage.gitResolvedRef}" installed globally.');
        return globalPackage.name;
      } else {
        logger?.trace(
            'Found package installed from "${globalPackage.url}" at ref "${globalPackage.gitResolvedRef}" installed globally, but latest ref is "$latestResolvedRef"');
        return null;
      }
    }
  }

  return null;
}
