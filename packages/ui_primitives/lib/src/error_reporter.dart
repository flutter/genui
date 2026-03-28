import 'foundation/assertions.dart';

class FrameworkErrorReporter {
  /// Set this instance to customize error reporting for the framework.
  static FrameworkErrorReporter instance = FrameworkErrorReporter();

  /// Creates a new [FrameworkError] instance.
  FrameworkError create({String? message, FrameworkErrorDetails? details}) =>
      FrameworkError(message: message, details: details);

  /// Reports a [FrameworkError] according to the framework settings.
  void report({String? message, FrameworkErrorDetails? details}) =>
      throw FrameworkError(message: message, details: details);
}

class FrameworkError extends Error {
  FrameworkError({this.message, this.details});

  final String? message;
  final FrameworkErrorDetails? details;

  @override
  String toString() {
    return message ?? details.toString();
  }
}
