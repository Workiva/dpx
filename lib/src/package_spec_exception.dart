class PackageSpecException extends FormatException {
  PackageSpecException(String message, String packageSpec, [int? offset])
      : super(message, packageSpec, offset);
}
