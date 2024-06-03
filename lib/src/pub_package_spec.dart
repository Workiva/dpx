import 'package_spec.dart';

class PubPackageSpec extends PackageSpec {
  @override
  final String? packageExecutable;
  final String packageName;
  final String? pubServerUrl;
  final String? versionConstraint;

  PubPackageSpec(
    this.packageName, {
    this.packageExecutable,
    this.pubServerUrl,
    this.versionConstraint,
  });

  @override
  late final String description = _description();

  String _description() {
    final buffer = StringBuffer(packageName);
    if (versionConstraint != null) {
      buffer.write('@$versionConstraint');
    }
    if (packageExecutable != null) {
      buffer.write(' (executable "$packageExecutable")');
    }
    if (pubServerUrl != null) {
      buffer.write(' (from $pubServerUrl)');
    }
    return buffer.toString();
  }

  @override
  List<String> get pubGlobalActivateArgs => [
        packageName,
        if (versionConstraint != null) versionConstraint!,
        if (pubServerUrl != null) '--hosted-url=$pubServerUrl',
      ];
}
