import 'dart:collection';

import 'package_spec_exception.dart';

class PackageSpecScanner {
  int get offset => _consumed.length;

  final String packageSpec;
  final Queue<String> _chars;
  String _consumed = '';
  String _pending = '';

  PackageSpecScanner(this.packageSpec)
      : _chars = Queue.from(packageSpec.split(''));

  /// Whether the remaining characters include [token].
  bool contains(String token) => _chars.contains(token);

  /// Number of times [token] appears in the remaining characters.
  int count(String token) => _chars.where((char) => char == token).length;

  bool get isEmpty => _chars.isEmpty;
  bool get isNotEmpty => _chars.isNotEmpty;

  /// Returns the next character (if present) without consuming it.
  String? peekNext() => _chars.isNotEmpty ? _chars.first : null;

  /// Returns the string of characters up until [token] without consuming any of
  /// them (in other words, without advancing the cursor at all).
  String peekUntil(String token) {
    final buffer = StringBuffer();
    for (final char in _chars) {
      if (char == token) break;
      buffer.write(char);
    }
    return buffer.toString();
  }

  /// Consumes the next character if it matches [token], otherwise throws an
  /// exception.
  ///
  /// Note: this does _not_ call [validate], so you must call it after this.
  void consume(String token) {
    if (_chars.isEmpty) {
      exception('Expected "$token" but reached end of string');
    }
    final next = _chars.removeFirst();
    if (next != token) {
      exception('Expected "$token" but found "$next"');
    }
    _pending += next;
  }

  /// Consumes the next character only if it matches [token].
  ///
  /// Note: this does _not_ call [validate], so you must call it after this.
  bool consumeIf(String token) {
    if (peekNext() == token) {
      consume(token);
      return true;
    }
    return false;
  }

  /// Consumes and returns the rest of the characters.
  ///
  /// If the returned string is invalid for any reason, call [exception] to
  /// throw an exception with a pointer to the beginning of this substring.
  /// Otherwise, call [validate], which will advance [offset] past it.
  String consumeRest() {
    final rest = _chars.join('');
    _chars.clear();
    _pending += rest;
    return rest;
  }

  /// Consumes and returns the string of characters up until any of [tokens].
  ///
  /// If any of [tokens] is found, it will not be consumed.
  ///
  /// If none of [tokens] are found, then the remainder of the spec will be
  /// consumed and returned.
  ///
  /// If the returned string is invalid for any reason, call [exception] to
  /// throw an exception with a pointer to the beginning of this substring.
  /// Otherwise, call [validate], which will advance [offset] past it.
  String consumeUntil(String token) => consumeUntilAny([token]);

  /// Consumes and returns the string of characters up until any of [tokens].
  ///
  /// If any of [tokens] is found, it will not be consumed.
  ///
  /// If none of [tokens] are found, then the remainder of the spec will be
  /// consumed and returned.
  ///
  /// If the returned string is invalid for any reason, call [exception] to
  /// throw an exception with a pointer to the beginning of this substring.
  /// Otherwise, call [validate], which will advance [offset] past it.
  String consumeUntilAny(List<String> tokens) {
    final result = StringBuffer();
    while (_chars.isNotEmpty) {
      // Peek.
      final next = _chars.first;

      if (tokens.contains(next)) {
        // Break without consuming and without adding to the result.
        break;
      }

      // At this point we can actually consume it and add it to the result.
      result.write(next);
      _pending += _chars.removeFirst();
    }
    return result.toString();
  }

  /// Throws a [PackageSpecException] with a pointer to the beginning of the
  /// last substring of [packageSpec] consumed via [consumeThrough].
  Never exception(String message) =>
      throw PackageSpecException(message, packageSpec, offset);

  /// Marks the last string consumed via [consumeUntil] as valid.
  void validate() {
    _consumed += _pending;
    _pending = '';
  }
}
