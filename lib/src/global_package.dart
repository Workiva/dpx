import 'package:pub_semver/pub_semver.dart';

class GlobalPackage {
  /// Name of the package.
  final String name;

  /// Source the package was installed from (hosted, git, or path).
  final String source;

  /// Version of the package (from its pubspec.yaml).
  ///
  /// Should only be used for hosted packages.
  final Version version;

  /// For hosted packages, the pub server URL.
  /// For git packages, the git URL.
  /// For path packages, this will be null.
  final String? url;

  /// For git packages, the path within the repo that contains the package.
  final String? gitPath;

  // For git packages, the resolved ref that was checked out.
  final String? gitResolvedRef;

  // For path packages, the absolute path to the package dir.
  final String? path;

  GlobalPackage(
    this.name,
    this.source,
    this.version, {
    this.url,
    String? path,
    String? resolvedRef,
  })  : path = source == 'path' ? path : null,
        gitPath = source == 'git' ? path : null,
        gitResolvedRef = source == 'git' ? resolvedRef : null;

  @override
  String toString() =>
      'GlobalPackage(name: $name, source: $source, version: $version, url: $url, gitPath: $gitPath, gitResolvedRef: $gitResolvedRef, path: $path)';
}
