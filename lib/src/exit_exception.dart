class ExitException implements Exception {
  final int exitCode;
  final String message;
  ExitException(this.exitCode, this.message);
}
