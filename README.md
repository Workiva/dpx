# `dpx` - execute Dart package binaries

## Installation

```bash
dart pub global activate dpx
```

For ease of use, [follow these instructions][dart run from path] to add the
system cache `bin` directory to your path so that you can run `dpx` directly.

## Usage

```bash
dpx <package-spec>[:<package-executable>] [-e <executable>] [args...]
```

First, dpx will globally activate the package specified by `<package-spec>`.
Then it will run a command.

If neither `:<package-executable>` nor `-e <executable>` are specified, dpx will
run the default package executable from `<package>`. This is equivalent to:

```bash
dart pub global run <package> [args...]
```

If `:<package-executable>` is specified, dpx will run that executable from the
installed package. This is equivalent to:

```bash
dart pub global run <package>:<package-executable> [args...]
```

If `-e <executable>` is specified, dpx will run `<executable> [args...]`
directly after installing the package. This allows you to opt-out of the default
method that uses `dart pub global run`. This may be useful for Dart packages
that declare an [executable in the pubspec][pubspec executable] that would be
available in the PATH, or if other executables outside of the package need to be
used.

## Exit Status

| Exit Code | Meaning                                              |
| --------- | ---------------------------------------------------- |
| 0         | Success                                              |
| >0        | Error                                                |
| 126       | Target command was found, but could not be executed. |
| 127       | Target command could not be found.                   |

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
dpx pub@<pub-server>:<package>[@<version-constraint] [args...]
# Example:
dpx pub@pub.workiva.org:dart_null_tools@^1.0.0

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
dpx <git-url>#path=sub/dir,ref=v1.0.2 [args...]
# Examples:
dpx github:Workiva/dpx#ref=v0.1.0 --help
dpx github:Workiva/dpx#path=example/dpx_hello
dpx github:Workiva/dpx#path=example/dpx_hello,ref=v0.1.0
```

## Troubleshooting

If you encounter any issues, please run the command again with `--verbose`:

```bash
dpx --verbose ...
```

This will provide a lot more detail that might help identify the cause of your
issue. If not, please [open an issue][new issue] and include the verbose logs.

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
