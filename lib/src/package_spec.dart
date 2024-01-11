import 'package:pub_semver/pub_semver.dart';

import 'git_options.dart';
import 'git_package_spec.dart';
import 'package_spec_scanner.dart';
import 'pub_package_spec.dart';

const _supportedSchemes = [
  'git',
  'github',
  'github+ssh',
  'https',
  'pub',
  'ssh'
];

final _githubOrgAndRepoValidator = RegExp(r'^[\w-]+$');
final _packageNameValidator = RegExp(r'^[a-zA-Z]\w*$');

abstract class PackageSpec {
  static PackageSpec parse(String packageSpec) {
    // With one exception, package specs should always start with a scheme that
    // determines how we parse the rest of the spec. The one exception is the
    // default case of referencing a package from the public pub.dev pub server,
    // in which case the scheme can be omitted for brevity. When omitted, this
    // parsing logic fills in the omission with the equivalent info.

    final scanner = PackageSpecScanner(packageSpec);

    String scheme;
    String? schemeUrl;

    if (!scanner.contains(':')) {
      // The only case where the scheme can be omitted is when referencing a
      // package published to the public pub.dev server.
      scheme = 'pub';
    } else {
      // Otherwise, a scheme was explicitly specified.
      scheme = scanner.peekUntil(':');

      // Some schemes allow a configurable element, like the URL of the pub server
      // or git server. In those cases, the scheme is in this format: <scheme>@<url>
      if (scheme.contains('@')) {
        // Validate the scheme.
        scheme = scanner.consumeThrough('@');
        if (_supportedSchemes.contains(scheme)) {
          scanner.validate();
        } else {
          scanner.exception('Unsupported package-spec scheme: $scheme');
        }

        // Next, validate the scheme URL.
        schemeUrl = scanner.consumeThrough(':');
        if (schemeUrl.isNotEmpty && Uri.tryParse(schemeUrl) != null) {
          scanner.validate();
        } else {
          scanner.exception('Invalid URL in package-spec scheme.');
        }
      } else {
        // Validate the scheme.
        scheme = scanner.consumeThrough(':');
        if (_supportedSchemes.contains(scheme)) {
          scanner.validate();
        } else {
          scanner.exception('Unsupported package-spec scheme: $scheme');
        }
      }
    }

    if (scheme == 'pub') {
      // We've already scanned the scheme, so the remaining syntax is:
      // <pkg>[@<version-constraint>]

      // Add `https://` to the pub server URL.
      if (schemeUrl != null && !Uri.parse(schemeUrl).hasScheme) {
        schemeUrl = 'https://$schemeUrl';
      }

      // Consume and validate the package name.
      final packageName = scanner.consumeThrough('@');
      if (_packageNameValidator.hasMatch(packageName)) {
        scanner.validate();
      } else {
        scanner.exception('Invalid package name: $packageName');
      }

      // Consume and validate the version constraint, if present.
      String? versionConstraint;
      if (scanner.isNotEmpty) {
        versionConstraint = scanner.consumeRest();
        try {
          VersionConstraint.parse(versionConstraint);
          scanner.validate();
        } on FormatException catch (e) {
          scanner.exception(e.toString());
        }
      }

      return PubPackageSpec(
        packageName,
        pubServerUrl: schemeUrl,
        versionConstraint: versionConstraint,
      );
    }

    GitOptions parseGitFragment() {
      // Syntax of the git fragment is: [#path:<git-path>[,ref:<git-ref>]]
      // But note, the `#` will have already been consumed.
      String? gitPath, gitRef;

      while (scanner.isNotEmpty) {
        final optionKey = scanner.consumeThrough(':');
        if (optionKey == 'path') {
          scanner.validate();
          gitPath = scanner.consumeThrough(',');
          scanner.validate();
        } else if (optionKey == 'ref') {
          scanner.validate();
          gitRef = scanner.consumeThrough(',');
          scanner.validate();
        } else {
          scanner.exception(
              'Unknown option "$optionKey" in fragment of git-based package spec');
        }
      }

      return GitOptions(gitPath: gitPath, gitRef: gitRef);
    }

    // Git shorthands
    if (scheme == 'github' || scheme == 'github+ssh') {
      // We've already scanned the scheme, so the remaining syntax is:
      // <org>/<repo>[#path:<git-path>[,ref:<git-ref>]]

      // Consume and validate the github org.
      final org = scanner.consumeThrough('/');
      if (_githubOrgAndRepoValidator.hasMatch(org)) {
        scanner.validate();
      } else {
        scanner.exception('Invalid github org: "$org"');
      }

      // Consume and validate the github repo.
      final repo = scanner.consumeThrough('#');
      if (_githubOrgAndRepoValidator.hasMatch(repo)) {
        scanner.validate();
      } else {
        scanner.exception('Invalid github repo: "$repo"');
      }

      // Parse and validate the git options in the fragment, if present.
      final options = parseGitFragment();

      final newUrl =
          scheme == 'github' ? 'https://github.com' : 'ssh://git@github.com';
      return GitPackageSpec(
        '$newUrl/$org/$repo.git',
        gitPath: options.gitPath,
        gitRef: options.gitRef,
      );
    }

    // `git@<url>:...` syntax (Github uses this format for SSH)
    if (scheme == 'git') {
      // We've already scanned the scheme, so the remaining syntax is:
      // <git-url-path>[#path:<git-path>[,ref:<git-ref>]]

      // The `git` scheme _must_ specify a git server URL.
      if (schemeUrl == null) {
        scanner.exception(
            'The "git" scheme must include a server URL: "git@<server>:<path>.git"');
      }

      // Validate the git URL.
      if (Uri.tryParse(schemeUrl) == null) {
        scanner.exception('Invalid git sever URL: $schemeUrl');
      }

      // Consume and validate the path of the git URL.
      final gitUrlPath = scanner.consumeThrough('#');
      scanner.validate();

      // Parse and validate the git options in the fragment, if present.
      final options = parseGitFragment();

      return GitPackageSpec(
        'ssh://git@$schemeUrl/$gitUrlPath',
        gitPath: options.gitPath,
        gitRef: options.gitRef,
      );
    }

    if (scheme == 'https' || scheme == 'ssh') {
      // At this point we assume that any `https` or `ssh` URLs are git URLs.
      // We've already scanned the scheme, so the remaining syntax is:
      // <git-url>[#path:<git-path>[,ref:<git-ref>]]

      // Consume and validate the git URL.
      final gitUrl = '$scheme:${scanner.consumeThrough('#')}';
      if (Uri.tryParse(gitUrl) != null) {
        scanner.validate();
      } else {
        scanner.exception('Invalid git URL: $gitUrl');
      }

      // Consume and validate the git options in the fragment, if present.
      final options = parseGitFragment();

      return GitPackageSpec(
        gitUrl,
        gitPath: options.gitPath,
        gitRef: options.gitRef,
      );
    }

    // Shouldn't be possible to get here, but just in case:
    scanner.exception('Unsupported package-spec scheme: $scheme');
  }

  String get description;

  List<String> get pubGlobalActivateArgs;

  @override
  String toString() => '$runtimeType($description)';
}
