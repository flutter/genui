import 'foundation/assertions.dart';

class FrameworkErrorReporter {
  static FrameworkErrorReporter instance = FrameworkErrorReporter();

  Error create(FrameworkErrorDetails details) => Error();

  void report() {}
}
