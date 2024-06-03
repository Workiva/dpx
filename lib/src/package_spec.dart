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

final _packageExecutableNameValidator = RegExp(r'^[a-zA-Z][\w-]*$');
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

    if (scanner.count(':') > 2) {
      scanner.exception('Invalid package-spec format: too many colons');
    } else if (scanner.count(':') == 0) {
      // The only case where the scheme can be omitted is when referencing a
      // package published to the public pub.dev server.
      scheme = 'pub';
    } else {
      // Otherwise, there are two cases:
      // (1) There are two colons, which is valid only if both the scheme and
      // the executable are specified:
      //   <scheme>:<source>:<package-executable>
      //
      // (2) There is one colon, which is valid if either the scheme or the
      // package executable is specified, but not both:
      //   <scheme>:<source> OR <source>:<package-executable>
      //
      // The second case involves an ambiguity in that a package could share the
      // name of one of our supported schemes:
      //   ssh:cmd <-- is this referencing a package called "cmd" using the "ssh" scheme?
      //               or a package called "ssh" using the "cmd" package-executable?
      //
      // To disambiguate, we'll break this into two sub-cases by peeking at what
      // the scheme would be:
      // (2a) If a supported scheme is found in the first position, assume
      // that it was meant to be a scheme. **Note: this should be rare, as the
      // schemes we support today either do not have matching packages on the
      // public pub server, or the matching packages don't have executables.**
      // (2b) If a supported scheme is not found in the first position, fall
      // back to the default scheme and assume that the package-executable was
      // specified.

      // In all of these cases, we start by peeking at the scheme.
      scheme = scanner.peekUntil(':');
      final containsSchemeOptions = scheme.contains('@');
      if (containsSchemeOptions) {
        scheme = scheme.split('@').first;
      }

      // If the scheme is not valid..
      if (!_supportedSchemes.contains(scheme)) {
        if (scanner.count(':') == 2) {
          // (Case 1) and there are two colons, this is invalid. The scheme must
          // be specified.
          scanner.exception('Unsupported package-spec scheme: $scheme');
        } else {
          // (Case 2b) and there is one colon, so we fall back to the default.
          scheme = 'pub';
        }
      } else {
        // (Case 1 & 2a) A valid scheme was found, so now we finish validating
        // and consuming it.
        if (containsSchemeOptions) {
          // Some schemes allow a configurable element, like the URL of the pub
          // server or git server. In those cases, the scheme is in this format:
          // <scheme>@<url>
          scanner
            ..consumeUntil('@')
            ..consume('@')
            ..validate();

          // Next, validate the scheme URL.
          schemeUrl = scanner.consumeUntil(':');
          scanner.consume(':');
          if (schemeUrl.isNotEmpty && Uri.tryParse(schemeUrl) != null) {
            scanner.validate();
          } else {
            scanner.exception('Invalid URL in package-spec scheme.');
          }
        } else {
          scanner
            ..consumeUntil(':')
            ..consume(':')
            ..validate();
        }
      }
    }

    /// Consume and validate the package executable, if present.
    String? maybeConsumePackageExecutable() {
      String? packageExecutable;
      if (scanner.isNotEmpty) {
        scanner.consume(':');
        packageExecutable = scanner.consumeRest();
        if (_packageExecutableNameValidator.hasMatch(packageExecutable)) {
          scanner.validate();
        } else {
          scanner.exception('Invalid package executable: $packageExecutable');
        }
      }
      return packageExecutable;
    }

    if (scheme == 'pub') {
      // We've already scanned the scheme, so the remaining syntax is:
      // <pkg>[@<version-constraint>][:<package-executable>]

      // Add `https://` to the pub server URL.
      if (schemeUrl != null && !Uri.parse(schemeUrl).hasScheme) {
        schemeUrl = 'https://$schemeUrl';
      }

      // Consume and validate the package name.
      final packageName = scanner.consumeUntilAny(['@', ':']);
      if (_packageNameValidator.hasMatch(packageName)) {
        scanner.validate();
      } else {
        scanner.exception('Invalid package name: $packageName');
      }

      // Consume and validate the version constraint, if present.
      String? versionConstraint;
      if (scanner.consumeIf('@')) {
        versionConstraint = scanner.consumeUntil(':');
        try {
          VersionConstraint.parse(versionConstraint);
          scanner.validate();
        } on FormatException catch (e) {
          scanner.exception(e.toString());
        }
      }

      // Consume and validate the package executable, if present.
      final packageExecutable = maybeConsumePackageExecutable();

      return PubPackageSpec(
        packageName,
        packageExecutable: packageExecutable,
        pubServerUrl: schemeUrl,
        versionConstraint: versionConstraint,
      );
    }

    GitOptions parseGitFragment() {
      // Syntax of the git fragment is: [#path=<git-path>[,ref=<git-ref>]]
      String? gitPath, gitRef;

      scanner.consumeIf('#');
      while (scanner.isNotEmpty && scanner.peekNext() != ':') {
        final optionKey = scanner.consumeUntil('=');
        scanner.consume('=');
        if (optionKey == 'path') {
          scanner.validate();
          gitPath = scanner.consumeUntilAny([',', ':']);
          scanner.consumeIf(',');
          scanner.validate();
        } else if (optionKey == 'ref') {
          scanner.validate();
          gitRef = scanner.consumeUntilAny([',', ':']);
          scanner.consumeIf(',');
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
      // <org>/<repo>[#path=<git-path>[,ref=<git-ref>]][:<package-executable>]

      // Consume and validate the github org.
      final org = scanner.consumeUntil('/');
      scanner.consume('/');
      if (_githubOrgAndRepoValidator.hasMatch(org)) {
        scanner.validate();
      } else {
        scanner.exception('Invalid github org: "$org"');
      }

      // Consume and validate the github repo.
      final repo = scanner.consumeUntilAny(['#', ':']);
      if (_githubOrgAndRepoValidator.hasMatch(repo)) {
        scanner.validate();
      } else {
        scanner.exception('Invalid github repo: "$repo"');
      }

      // Parse and validate the git options in the fragment, if present.
      final options = parseGitFragment();

      // Consume and validate the package executable, if present.
      final packageExecutable = maybeConsumePackageExecutable();

      final newUrl =
          scheme == 'github' ? 'https://github.com' : 'ssh://git@github.com';
      return GitPackageSpec(
        '$newUrl/$org/$repo.git',
        gitPath: options.gitPath,
        gitRef: options.gitRef,
        packageExecutable: packageExecutable,
      );
    }

    // `git@<url>:...` syntax (Github uses this format for SSH)
    if (scheme == 'git') {
      // We've already scanned the scheme, so the remaining syntax is:
      // <git-url-path>[#path:<git-path>[,ref:<git-ref>]][:<package-executable>]

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
      final gitUrlPath = scanner.consumeUntilAny(['#', ':']);
      scanner.validate();

      // Parse and validate the git options in the fragment, if present.
      final options = parseGitFragment();

      // Consume and validate the package executable, if present.
      final packageExecutable = maybeConsumePackageExecutable();

      return GitPackageSpec(
        'ssh://git@$schemeUrl/$gitUrlPath',
        gitPath: options.gitPath,
        gitRef: options.gitRef,
        packageExecutable: packageExecutable,
      );
    }

    if (scheme == 'https' || scheme == 'ssh') {
      // At this point we assume that any `https` or `ssh` URLs are git URLs.
      // We've already scanned the scheme, so the remaining syntax is:
      // <git-url>[#path:<git-path>[,ref:<git-ref>]][:<package-executable>]

      // Consume and validate the git URL.
      final gitUrl = '$scheme:${scanner.consumeUntilAny(['#', ':'])}';
      if (Uri.tryParse(gitUrl) != null) {
        scanner.validate();
      } else {
        scanner.exception('Invalid git URL: $gitUrl');
      }

      // Consume and validate the git options in the fragment, if present.
      final options = parseGitFragment();

      // Consume and validate the package executable, if present.
      final packageExecutable = maybeConsumePackageExecutable();

      return GitPackageSpec(
        gitUrl,
        gitPath: options.gitPath,
        gitRef: options.gitRef,
        packageExecutable: packageExecutable,
      );
    }

    // Shouldn't be possible to get here, but just in case:
    scanner.exception('Unsupported package-spec scheme: $scheme');
  }

  String get description;

  String? get packageExecutable;

  List<String> get pubGlobalActivateArgs;

  @override
  String toString() => '$runtimeType($description)';
}
