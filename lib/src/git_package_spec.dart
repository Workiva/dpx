import 'package_spec.dart';

class GitPackageSpec extends PackageSpec {
  final String gitUrl;
  final String? gitPath;
  final String? gitRef;

  GitPackageSpec(this.gitUrl, {this.gitPath, this.gitRef});

  @override
  late final String description = _description();

  String _description() {
    final buffer = StringBuffer('Git repository "$gitUrl"');
    if (gitPath != null && gitRef != null) {
      buffer.write(' at path "$gitPath" and ref "$gitRef"');
    } else if (gitPath != null) {
      buffer.write(' at path "$gitPath"');
    } else if (gitRef != null) {
      buffer.write(' at ref "$gitRef"');
    }
    return buffer.toString();
  }

  @override
  List<String> get pubGlobalActivateArgs => [
        '--source=git',
        gitUrl,
        if (gitPath != null) '--git-path=$gitPath',
        if (gitRef != null) '--git-ref=$gitRef',
      ];
}
