import 'foundation/assertions.dart';

class FrameworkErrorReporter {
  static FrameworkErrorReporter instance = FrameworkErrorReporter();

  Error create(String message) => Error();

  void report(FrameworkErrorDetails details) => throw Error();
}
