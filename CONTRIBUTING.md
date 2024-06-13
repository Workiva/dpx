# Contributing

## Supported Dart Versions
Currently, `dpx` is written to support Dart 2.19 and Dart 3. We will eventually
drop support for Dart 2, but until then, all dependency ranges need to take this
into account and all CI checks (static analysis and tests) should pass on both
major versions of Dart. Additionally, language features that require Dart 3+ are
not yet used.

## Running Locally

- Install dependencies: `dart pub get`
- Analysis: `dart analyze`
- Tests: `dart test`
- Running:
  - `dart bin/dpx.dart`
  - `dart pub global activate -spath .` to activate and `dart pub global run dpx`
    to run (or just `dpx` if global Dart executables are added to your path).
- Debugging:
  - In VS Code, use the `DPX CLI` launch configuration. This will start `dpx` in
    interactive mode and open a terminal where you can enter the args. This will
    let you use the debugger and set breakpoints.
