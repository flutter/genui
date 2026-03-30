class FrameworkErrorReporter {
  /// Set this instance to customize error reporting for the framework.
  static FrameworkErrorReporter instance = FrameworkErrorReporter();

  Error errorByMessage(String message) => UnimplementedError(message);

  /// Reports [FrameworkErrorDetails] according to the framework settings.
  ///
  /// Depending on settings, it may throw an exception, log an error,
  /// or debug-stop the execution.
  void report(FrameworkErrorDetails details) => throw FrameworkError(details);
}

final class FrameworkError extends Error {
  FrameworkError(this.details);

  final FrameworkErrorDetails details;

  String get message => details.message ?? details.toString();

  @override
  String toString() => message;
}

final class FrameworkErrorDetails extends Error {
  FrameworkErrorDetails({
    required this.exception,
    this.dispatchingObject,
    this.contextCollector,
    this.stack,
    this.message,
    this.library,
  });

  final String? message;
  final String? library;
  final Object? dispatchingObject;
  final Object exception;
  final ContextCollector? contextCollector;
  final StackTrace? stack;
}

// Interface for Flutter's InformationCollector.
typedef ContextCollector = Iterable<ValueContext> Function();

// Interface for Flutter's DiagnosticsNode.
final class ValueContext {
  final Object? context;
  final Object? value;

  ValueContext({this.context, this.value});
}
