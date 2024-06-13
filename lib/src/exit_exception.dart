class ExitException implements Exception {
  final int exitCode;
  final String message;
  final StackTrace? stackTrace;
  ExitException(this.exitCode, this.message, [this.stackTrace]);
}
