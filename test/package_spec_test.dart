import 'package:dpx/src/git_package_spec.dart';
import 'package:dpx/src/package_spec.dart';
import 'package:dpx/src/package_spec_exception.dart';
import 'package:dpx/src/pub_package_spec.dart';
import 'package:test/test.dart';

Matcher isGitPackageSpec(
  String gitUrl, {
  String? executable,
  String? path,
  String? ref,
}) {
  return isA<GitPackageSpec>()
      .having((s) => s.gitUrl, 'gitUrl', gitUrl)
      .having((s) => s.gitPath, 'gitPath', path ?? isNull)
      .having((s) => s.gitRef, 'gitRef', ref ?? isNull)
      .having((s) => s.packageExecutable, 'packageExecutable',
          executable ?? isNull);
}

Matcher isPubPackageSpec(
  String packageName, {
  String? executable,
  String? constraint,
  String? server,
}) {
  return isA<PubPackageSpec>()
      .having((s) => s.packageName, 'packageName', packageName)
      .having(
          (s) => s.packageExecutable, 'packageExecutable', executable ?? isNull)
      .having((s) => s.pubServerUrl, 'pubServerUrl', server ?? isNull)
      .having((s) => s.versionConstraint, 'versionConstraint',
          constraint ?? isNull);
}

void main() {
  group('PackageSpec.parse', () {
    group('(scheme=pub)', () {
      test('pkg', () {
        final spec = PackageSpec.parse('dpx');
        expect(spec, isPubPackageSpec('dpx'));
        expect(spec.description, 'dpx');
        expect(spec.pubGlobalActivateArgs, orderedEquals(['dpx']));
      });

      test('pkg with executable', () {
        final spec = PackageSpec.parse('dpx:exe');
        expect(spec, isPubPackageSpec('dpx', executable: 'exe'));
        expect(spec.description, 'dpx (executable "exe")');
        expect(spec.pubGlobalActivateArgs, orderedEquals(['dpx']));
      });

      test('pkg with constraint', () {
        final spec = PackageSpec.parse('dpx@^1.0.0');
        expect(spec, isPubPackageSpec('dpx', constraint: '^1.0.0'));
        expect(spec.description, 'dpx@^1.0.0');
        expect(spec.pubGlobalActivateArgs, orderedEquals(['dpx', '^1.0.0']));
      });

      test('pkg with constraint and executable', () {
        final spec = PackageSpec.parse('dpx@^1.0.0:exe');
        expect(spec,
            isPubPackageSpec('dpx', constraint: '^1.0.0', executable: 'exe'));
        expect(spec.description, 'dpx@^1.0.0 (executable "exe")');
        expect(spec.pubGlobalActivateArgs, orderedEquals(['dpx', '^1.0.0']));
      });

      test('pkg with constraint containing whitespace', () {
        // Note: this may look invalid, but it will work as long as the CLI user
        // surrounds the full argument in quotes.
        // Example: dpx "foo@>=1.0.0 <3.0.0"
        final spec = PackageSpec.parse('dpx@>=1.0.0 <3.0.0');
        expect(spec, isPubPackageSpec('dpx', constraint: '>=1.0.0 <3.0.0'));
        expect(spec.description, 'dpx@>=1.0.0 <3.0.0');
        expect(spec.pubGlobalActivateArgs,
            orderedEquals(['dpx', '>=1.0.0 <3.0.0']));
      });

      test('pkg with executable and constraint containing whitespace', () {
        final spec = PackageSpec.parse('dpx@>=1.0.0 <3.0.0:exe');
        expect(
            spec,
            isPubPackageSpec('dpx',
                constraint: '>=1.0.0 <3.0.0', executable: 'exe'));
        expect(spec.description, 'dpx@>=1.0.0 <3.0.0 (executable "exe")');
        expect(spec.pubGlobalActivateArgs,
            orderedEquals(['dpx', '>=1.0.0 <3.0.0']));
      });

      test('pkg from custom pub', () {
        final spec = PackageSpec.parse('pub@custom.pub.dev:dpx');
        expect(spec, isPubPackageSpec('dpx', server: 'https://custom.pub.dev'));
        expect(spec.description, 'dpx (from https://custom.pub.dev)');
        expect(spec.pubGlobalActivateArgs,
            orderedEquals(['dpx', '--hosted-url=https://custom.pub.dev']));
      });

      test('pkg with executable from custom pub', () {
        final spec = PackageSpec.parse('pub@custom.pub.dev:dpx:exe');
        expect(
            spec,
            isPubPackageSpec('dpx',
                executable: 'exe', server: 'https://custom.pub.dev'));
        expect(spec.description,
            'dpx (executable "exe") (from https://custom.pub.dev)');
        expect(spec.pubGlobalActivateArgs,
            orderedEquals(['dpx', '--hosted-url=https://custom.pub.dev']));
      });

      test('pkg with constraint from custom pub', () {
        final spec = PackageSpec.parse('pub@custom.pub.dev:dpx@^1.0.0');
        expect(
            spec,
            isPubPackageSpec('dpx',
                constraint: '^1.0.0', server: 'https://custom.pub.dev'));
        expect(spec.description, 'dpx@^1.0.0 (from https://custom.pub.dev)');
        expect(
            spec.pubGlobalActivateArgs,
            orderedEquals(
                ['dpx', '^1.0.0', '--hosted-url=https://custom.pub.dev']));
      });

      test('pkg with executable and constraint from custom pub', () {
        final spec = PackageSpec.parse('pub@custom.pub.dev:dpx@^1.0.0:exe');
        expect(
            spec,
            isPubPackageSpec('dpx',
                constraint: '^1.0.0',
                executable: 'exe',
                server: 'https://custom.pub.dev'));
        expect(spec.description,
            'dpx@^1.0.0 (executable "exe") (from https://custom.pub.dev)');
        expect(
            spec.pubGlobalActivateArgs,
            orderedEquals(
                ['dpx', '^1.0.0', '--hosted-url=https://custom.pub.dev']));
      });

      test('validates package name', () {
        expect(() => PackageSpec.parse('09/invalid'),
            throwsA(isA<PackageSpecException>()));
      });

      test('validates executable name', () {
        expect(() => PackageSpec.parse('dpx:09/invalid'),
            throwsA(isA<PackageSpecException>()));
      });

      test('validates version constraint', () {
        expect(() => PackageSpec.parse('dpx@--'),
            throwsA(isA<PackageSpecException>()));
      });
    });

    void testGitOptions(String unparsedSpec, String gitUrl) {
      test('with git path', () {
        final path = 'sub/dir';
        final spec = PackageSpec.parse('$unparsedSpec#path=$path');
        expect(spec, isGitPackageSpec(gitUrl, path: path));
        expect(spec.description, 'Git repository "$gitUrl" at path "$path"');
        expect(
            spec.pubGlobalActivateArgs,
            orderedEquals([
              '--source=git',
              gitUrl,
              '--git-path=$path',
            ]));
      });

      test('with git ref', () {
        final ref = 'my-feature/v1';
        final spec = PackageSpec.parse('$unparsedSpec#ref=$ref');
        expect(spec, isGitPackageSpec(gitUrl, ref: ref));
        expect(spec.description, 'Git repository "$gitUrl" at ref "$ref"');
        expect(
            spec.pubGlobalActivateArgs,
            orderedEquals([
              '--source=git',
              gitUrl,
              '--git-ref=$ref',
            ]));
      });

      test('with git path and git ref', () {
        final path = 'sub/dir';
        final ref = 'my-feature/v1';
        final spec = PackageSpec.parse('$unparsedSpec#path=$path,ref=$ref');
        expect(spec, isGitPackageSpec(gitUrl, path: path, ref: ref));
        expect(spec.description,
            'Git repository "$gitUrl" at path "$path" and ref "$ref"');
        expect(
            spec.pubGlobalActivateArgs,
            orderedEquals([
              '--source=git',
              gitUrl,
              '--git-path=$path',
              '--git-ref=$ref',
            ]));
      });

      test('with executable', () {
        final spec = PackageSpec.parse('$unparsedSpec:exe');
        expect(spec, isGitPackageSpec(gitUrl, executable: 'exe'));
        expect(spec.description, 'Git repository "$gitUrl" (executable "exe")');
        expect(spec.pubGlobalActivateArgs,
            orderedEquals(['--source=git', gitUrl]));
      });

      test('with executable and git path', () {
        final path = 'sub/dir';
        final spec = PackageSpec.parse('$unparsedSpec#path=$path:exe');
        expect(spec, isGitPackageSpec(gitUrl, path: path, executable: 'exe'));
        expect(spec.description,
            'Git repository "$gitUrl" at path "$path" (executable "exe")');
        expect(
            spec.pubGlobalActivateArgs,
            orderedEquals([
              '--source=git',
              gitUrl,
              '--git-path=$path',
            ]));
      });

      test('with executable and git ref', () {
        final ref = 'my-feature/v1';
        final spec = PackageSpec.parse('$unparsedSpec#ref=$ref:exe');
        expect(spec, isGitPackageSpec(gitUrl, ref: ref, executable: 'exe'));
        expect(spec.description,
            'Git repository "$gitUrl" at ref "$ref" (executable "exe")');
        expect(
            spec.pubGlobalActivateArgs,
            orderedEquals([
              '--source=git',
              gitUrl,
              '--git-ref=$ref',
            ]));
      });

      test('with executable, git path, and git ref', () {
        final path = 'sub/dir';
        final ref = 'my-feature/v1';
        final spec = PackageSpec.parse('$unparsedSpec#path=$path,ref=$ref:exe');
        expect(spec,
            isGitPackageSpec(gitUrl, path: path, ref: ref, executable: 'exe'));
        expect(spec.description,
            'Git repository "$gitUrl" at path "$path" and ref "$ref" (executable "exe")');
        expect(
            spec.pubGlobalActivateArgs,
            orderedEquals([
              '--source=git',
              gitUrl,
              '--git-path=$path',
              '--git-ref=$ref',
            ]));
      });

      test('disallows unknown options', () {
        expect(() => PackageSpec.parse('$unparsedSpec#unknown=true'),
            throwsA(isA<PackageSpecException>()));
      });
    }

    void testValidatesGithubOrgAndRepo(String gitScheme) {
      test('validates org name', () {
        expect(() => PackageSpec.parse('$gitScheme:Org%<>/repo'),
            throwsA(isA<PackageSpecException>()));
      });

      test('validates repo name', () {
        expect(() => PackageSpec.parse('$gitScheme:Org/repo%<>'),
            throwsA(isA<PackageSpecException>()));
      });
    }

    group('(scheme=github) ', () {
      test('maps to https://', () {
        final spec = PackageSpec.parse('github:Org/repo');
        final gitUrl = 'https://github.com/Org/repo.git';
        expect(spec, isGitPackageSpec(gitUrl));
        expect(spec.description, 'Git repository "$gitUrl"');
        expect(spec.pubGlobalActivateArgs,
            orderedEquals(['--source=git', gitUrl]));
      });

      testGitOptions('github:Org/repo', 'https://github.com/Org/repo.git');
      testValidatesGithubOrgAndRepo('github');
    });

    group('(scheme=github+ssh)', () {
      test('maps to ssh://git@github.com', () {
        final spec = PackageSpec.parse('github+ssh:Org/repo');
        final gitUrl = 'ssh://git@github.com/Org/repo.git';
        expect(spec, isGitPackageSpec(gitUrl));
        expect(spec.description, 'Git repository "$gitUrl"');
        expect(spec.pubGlobalActivateArgs,
            orderedEquals(['--source=git', gitUrl]));
      });

      testGitOptions(
          'github+ssh:Org/repo', 'ssh://git@github.com/Org/repo.git');
      testValidatesGithubOrgAndRepo('github+ssh');
    });

    group('(scheme=git)', () {
      test('maps to ssh://git@<url>', () {
        final spec = PackageSpec.parse('git@github.com:Org/repo.git');
        final gitUrl = 'ssh://git@github.com/Org/repo.git';
        expect(spec, isGitPackageSpec(gitUrl));
        expect(spec.description, 'Git repository "$gitUrl"');
        expect(spec.pubGlobalActivateArgs,
            orderedEquals(['--source=git', gitUrl]));
      });

      test('requires git server URL', () {
        expect(() => PackageSpec.parse('git:Org/repo.git'),
            throwsA(isA<PackageSpecException>()));
      });

      test('validates git server URL', () {
        expect(() => PackageSpec.parse('git@:Org/repo.git'),
            throwsA(isA<PackageSpecException>()));
      });

      testGitOptions(
          'git@github.com:Org/repo.git', 'ssh://git@github.com/Org/repo.git');
    });

    group('(scheme=https)', () {
      test('', () {
        final gitUrl = 'https://github.com/Org/repo.git';
        final spec = PackageSpec.parse(gitUrl);
        expect(spec, isGitPackageSpec(gitUrl));
        expect(spec.description, 'Git repository "$gitUrl"');
        expect(spec.pubGlobalActivateArgs, ['--source=git', gitUrl]);
      });

      test('validates git server URL', () {
        expect(() => PackageSpec.parse('https://a:b/Org/repo.git'),
            throwsA(isA<PackageSpecException>()));
      });

      testGitOptions(
          'https://github.com/Org/repo.git', 'https://github.com/Org/repo.git');
    });

    group('(scheme=ssh)', () {
      test('', () {
        final gitUrl = 'ssh://git@github.com/Org/repo.git';
        final spec = PackageSpec.parse(gitUrl);
        expect(spec, isGitPackageSpec(gitUrl));
        expect(spec.description, 'Git repository "$gitUrl"');
        expect(spec.pubGlobalActivateArgs, ['--source=git', gitUrl]);
      });

      test('validates git server URL', () {
        expect(() => PackageSpec.parse('ssh://a:b/Org/repo.git'),
            throwsA(isA<PackageSpecException>()));
      });

      testGitOptions('ssh://git@github.com/Org/repo.git',
          'ssh://git@github.com/Org/repo.git');
    });
  });
}
