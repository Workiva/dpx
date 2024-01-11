import 'dart:io';

/// Prompts the user to select an action via stdin.
///
/// [letters] is the string of valid one-letter responses. In other words, if
/// [letters] is `yn` then the two valid responses are `y` and `n`.
///
/// [defaultChoice] will be returned if non-null and the user returns without
/// entering anything.
String prompt([String letters = 'yn', String? defaultChoice]) {
  while (true) {
    final response = stdin.readLineSync();
    if (response == null || response.length > 1) {
      stdout.writeln('Come again? (only enter a single character)');
      continue;
    }
    if (response.isNotEmpty && letters.contains(response)) {
      return response;
    }
    if (defaultChoice != null && response.isEmpty) {
      return defaultChoice;
    }
    stdout.writeln('Come again?');
  }
}
