# `dpx` - execute Dart package binaries

## Installation

Until this is published to pub, you'll have to install via Git:
```bash
dart pub global activate -sgit git@github.com:evanweible-wf/git_playground.git --git-ref=dpx/main
```

For ease of use, [follow these instructions][dart run from path] to add the
system cache `bin` directory to your path so that you can run `dpx` directly.

## Usage

```bash
# Execute a command from <pkg> with the same name as <pkg>
dpx <pkg> [args...]

# Execute <cmd> from <pkg>.
# Use if there are multiple executables or if the executable name is different.
dpx --package=<pkg> <cmd> [args...]
```

## Command Running

Once the necessary package is installed, dpx will attempt to run the command.

First, it tries to run the command directly, assuming that it is available as an
executable in the PATH. This works for Dart packages that declare an
[executable in the pubspec][pubspec executable].

```yaml
# pubspec.yaml
name: webdev
executables:
  webdev:
```

```bash
# Installs and runs `webdev` executable in PATH
dpx webdev
```

If that fails, dpx falls back to running the command with `dart pub global run`.
The expected format of a command run this way is `<pkg>:<cmd>`, where `<pkg>` is
the name of the Dart package and `<cmd>` is the name of the Dart file in `bin/`,
minus the `.dart` extension.

Dart lets you omit the `:<cmd>` portion if there's a file with the same name as
the package.

For other files, dpx lets you omit the `<pkg>` portion since it can be inferred.

```bash
dpx --package=build_runner :graph_inspector
```


## Package Sources

The first arg to `dpx` or the value of the `--package` option is referred to as
a `<package-spec>`, which supports several different formats to enable
installing from different sources and targeting specific versions.

```bash
# Install from pub with an optional version constraint.
# Syntax:
dpx <pkg>[@<version-constraint>] [args...]
# Example:
dpx webdev@^3.0.0 [args...]

# Install from custom pub server.
# Syntax:
dpx pub@<pub-server>:<pkg>[@<version-constraint] [args...]
# Example:
dpx pub@pub.workiva.org:workiva_nullsafety_migrator@^1.0.0

# Install from a github repo.
# Syntax:
dpx <git-url> [args...]
# Example:
dpx https://github.com/Workiva/dpx.git --help

# Shorthand for public github repos:
dpx github:<org>/<repo> [args...]

# Shorthand for private github repos:
dpx github+ssh:<org>/<repo> [args...]

# Optionally, all git-based package specs can specify:
# - <path> if the package is not in the root of the repo
# - <ref> to checkout a specific tag/branch/commit
# Syntax:
dpx <git-url>[#path:sub/dir,ref:v1.0.2] [args...]
# Examples:
dpx github:Workiva/dpx#ref:v0.0.0 --help
dpx github:Workiva/dpx#path:example/hello
dpx github:Workiva/dpx#path:example/hello,ref:v0.0.0
```

## Troubleshooting

If you encounter any issues, please run the command again with `--verbose`:

```bash
dpx --verbose ...
```

This will provide a lot more detail that might help identify an issue. If not,
please [open an issue][new issue] and include the verbose logs.

## Why the name?

It's like `npx`, but for **D**art.

**D**art **P**ackage e**X**ecute.

## Acknowledgements

`dpx` is inspired by the [`npx` package][npx package], which is now a part of
the [`npm` CLI][npx cli].

<!-- LINKS -->
[dart run from path]: https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path
[new issue]: https://github.com/Workiva/dpx/issues/new
[npx cli]: https://docs.npmjs.com/cli/v8/commands/npx
[npx package]: https://www.npmjs.com/package/npx
[pubspec executable]: https://dart.dev/tools/pub/pubspec#executables
