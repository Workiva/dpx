import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import 'exit_exception.dart';

/// Returns the absolute path to the system pub cache.
///
/// Borrowed from https://github.com/dart-lang/pub/blob/a3689f03168c896dd1cb0db8a60c568b38ee16bf/lib/src/system_cache.dart#L42
///
/// This is used to find the globally activated packages. Considered using the
/// output of `dart pub global list` instead, but it doesn't include the path,
/// ref, or resolved ref for git sources, which makes it impossible to determine
/// whether we can re-use a git source. If there's a way to do this without
/// relying on private implementation details, we should.
String getSystemCachePath({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;

  if (env.containsKey('PUB_CACHE')) {
    return env['PUB_CACHE']!;
  } else if (Platform.isWindows) {
    // %LOCALAPPDATA% is used as the cache location over %APPDATA%, because
    // the latter is synchronised between devices when the user roams between
    // them, whereas the former is not.
    final localAppData = env['LOCALAPPDATA'];
    if (localAppData == null) {
      throw ExitException(ExitCode.config.code, '''
Could not find the pub cache. No `LOCALAPPDATA` environment variable exists.
Consider setting the `PUB_CACHE` variable manually.
''');
    }
    return p.join(localAppData, 'Pub', 'Cache');
  } else {
    final home = Platform.environment['HOME'];
    if (home == null) {
      throw ExitException(ExitCode.config.code, '''
Could not find the pub cache. No `HOME` environment variable exists.
Consider setting the `PUB_CACHE` variable manually.
''');
    }
    return p.join(home, '.pub-cache');
  }
}
