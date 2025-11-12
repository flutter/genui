class ReleaseException implements Exception {
  final String message;

  ReleaseException(this.message);

  @override
  String toString() => message;
}
