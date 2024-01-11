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

  bool get isEmpty => _chars.isEmpty;
  bool get isNotEmpty => _chars.isNotEmpty;

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

  /// Consumes and returns the rest of the characters.
  ///
  /// If the returned string is invalid for any reason, call [exception] to
  /// throw an exception with a pointer to the beginning of this substring.
  /// Otherwise, call [validate], which will advance [offset] past it.
  String consumeRest() {
    final rest = _chars.join('');
    _chars.clear();
    return _pending = rest;
  }

  /// Consumes and returns the string of characters up until [token].
  ///
  /// If [token] is found, it will also be consumed, but it will not be included
  /// in the result. If [token] is not found, then the remainder of the spec
  /// will be consumed and returned.
  ///
  /// If the returned string is invalid for any reason, call [exception] to
  /// throw an exception with a pointer to the beginning of this substring.
  /// Otherwise, call [validate], which will advance [offset] past it.
  String consumeThrough(String token) {
    final buffer = StringBuffer();
    bool foundToken = false;
    while (_chars.isNotEmpty) {
      final next = _chars.removeFirst();
      if (next == token) {
        foundToken = true;
        break;
      }
      buffer.write(next);
    }
    _pending = buffer.toString() + (foundToken ? token : '');
    return buffer.toString();
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
