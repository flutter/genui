import 'primitives.dart';

class FrameworkErrorReporter {
  /// Set this instance to customize error reporting for the framework.
  static FrameworkErrorReporter instance = FrameworkErrorReporter();

  /// Creates a new [FrameworkErrorDetails] instance.
  FrameworkError errorByDetails(FrameworkErrorDetails details) =>
      FrameworkError(details);

  FrameworkError errorByMessage(String message) =>
      FrameworkError(FrameworkErrorDetails(message: message));

  /// Reports [FrameworkErrorDetails] according to the framework settings.
  ///
  /// Depending on settings, it may throw an exception, log an error,
  /// or debug-stop the execution.
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
    this.contextCollector,
    this.library,
    this.silent,
    this.stack,
    this.stackFilter,
    this.message,
  });

  final String? message;
  final ValueContext? context;
  final Object? exception;
  final ContextCollector? contextCollector;
  final String? library;
  final bool? silent;
  final StackTrace? stack;
  final IterableFilter<String>? stackFilter;
}

// Interface for Flutter's InformationCollector.
typedef ContextCollector = Iterable<ValueContext> Function();

// Interface for Flutter's DiagnosticsNode.
class ValueContext {
  final String? message;
  final String? value;

  ValueContext({this.message, this.value});
}
