import 'assertions.dart';

class FrameworkErrorReporter {
  /// Set this instance to customize error reporting for the framework.
  static FrameworkErrorReporter instance = FrameworkErrorReporter();

  /// Creates a new [FrameworkErrorDetails] instance.
  FrameworkError create(FrameworkErrorDetails details) =>
      FrameworkError(details);

  FrameworkError byMessage(String message) =>
      FrameworkError(FrameworkErrorDetails(message: message));

  /// Reports [FrameworkErrorDetails] according to the framework settings.
  void report(FrameworkErrorDetails details) => throw FrameworkError(details);
}

class FrameworkError extends Error {
  FrameworkError(this.details);

  final FrameworkErrorDetails details;

  String get message => details.message ?? details.toString();

  @override
  String toString() => message;
}

class FrameworkErrorDetails extends Error {
  FrameworkErrorDetails({
    this.context,
    this.exception,
    this.informationCollector,
    this.library,
    this.silent,
    this.stack,
    this.stackFilter,
    this.message,
  });

  final String? message;
  final DiagnosticsNode? context;
  final Object? exception;
  final InformationCollector? informationCollector;
  final String? library;
  final bool? silent;
  final StackTrace? stack;
  final IterableFilter<String>? stackFilter;
}
