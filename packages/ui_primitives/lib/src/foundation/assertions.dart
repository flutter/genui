// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:meta/meta.dart';

import 'basic_types.dart';
import 'constants.dart';
import 'diagnostics.dart';
import 'error_dumper.dart';
import 'error_reporter.dart';
import 'stack_frame.dart';

export 'basic_types.dart' show IterableFilter;
export 'diagnostics.dart'
    show
        DiagnosticLevel,
        DiagnosticPropertiesBuilder,
        DiagnosticsNode,
        DiagnosticsTreeStyle;
export 'stack_frame.dart' show StackFrame;

// Examples can assume:
// late String runtimeType;
// late bool draconisAlive;
// late bool draconisAmulet;
// late Diagnosticable draconis;
// void methodThatMayThrow() { }
// class Trace implements StackTrace { late StackTrace vmTrace; }
// class Chain implements StackTrace { Trace toTrace() => Trace(); }

/// Signature for [FrameworkError.onError] handler.
typedef FlutterExceptionHandler = void Function(FrameworkErrorDetails details);

/// Signature for [DiagnosticPropertiesBuilder] transformer.
typedef DiagnosticPropertiesTransformer =
    Iterable<DiagnosticsNode> Function(Iterable<DiagnosticsNode> properties);

/// Signature for [FrameworkErrorDetails.informationCollector] callback
/// and other callbacks that collect information describing an error.
typedef InformationCollector = Iterable<DiagnosticsNode> Function();

/// Signature for a function that demangles [StackTrace] objects into a format
/// that can be parsed by [StackFrame].
///
/// See also:
///
///   * [FrameworkError.demangleStackTrace], which shows an example
///     implementation.
typedef StackTraceDemangler = StackTrace Function(StackTrace details);

/// Partial information from a stack frame for stack filtering purposes.
///
/// See also:
///
///  * [RepetitiveStackFrameFilter], which uses this class to compare against
///    [StackFrame]s.
@immutable
class PartialStackFrame {
  /// Creates a new [PartialStackFrame] instance.
  const PartialStackFrame({
    required this.package,
    required this.className,
    required this.method,
  });

  /// An `<asynchronous suspension>` line in a stack trace.
  static const PartialStackFrame asynchronousSuspension = PartialStackFrame(
    package: '',
    className: '',
    method: 'asynchronous suspension',
  );

  /// The package to match, e.g.
  /// `package:flutter/src/foundation/assertions.dart`,
  /// or `dart:ui/window.dart`.
  final Pattern package;

  /// The class name for the method.
  ///
  /// On web, this is ignored, since class names are not available.
  ///
  /// On all platforms, top level methods should use the empty string.
  final String className;

  /// The method name for this frame line.
  ///
  /// On web, private methods are wrapped with `[]`.
  final String method;

  /// Tests whether the [StackFrame] matches the information in this
  /// [PartialStackFrame].
  bool matches(StackFrame stackFrame) {
    final stackFramePackage =
        '${stackFrame.packageScheme}:${stackFrame.package}/${stackFrame.packagePath}';
    // Ideally this wouldn't be necessary.
    // TODO(dnfield): https://github.com/dart-lang/sdk/issues/40117
    if (kIsWeb) {
      return package.allMatches(stackFramePackage).isNotEmpty &&
          stackFrame.method == (method.startsWith('_') ? '[$method]' : method);
    }
    return package.allMatches(stackFramePackage).isNotEmpty &&
        stackFrame.method == method &&
        stackFrame.className == className;
  }
}

/// A class that filters stack frames for additional filtering on
/// [FrameworkError.defaultStackFilter].
abstract class StackFilter {
  /// This constructor enables subclasses to provide const constructors so that
  /// they can be used in const expressions.
  const StackFilter();

  /// Filters the list of [StackFrame]s by updating corresponding indices in
  /// `reasons`.
  ///
  /// To elide a frame or number of frames, set the string.
  void filter(List<StackFrame> stackFrames, List<String?> reasons);
}

/// A [StackFilter] that filters based on repeating lists of
/// [PartialStackFrame]s.
///
/// See also:
///
///   * [FrameworkError.addDefaultStackFilter], a method to register additional
///     stack filters for [FrameworkError.defaultStackFilter].
///   * [StackFrame], a class that can help with parsing stack frames.
///   * [PartialStackFrame], a class that helps match partial method information
///     to a stack frame.
class RepetitiveStackFrameFilter extends StackFilter {
  /// Creates a new RepetitiveStackFrameFilter.
  const RepetitiveStackFrameFilter({
    required this.frames,
    required this.replacement,
  });

  /// The shape of this repetitive stack pattern.
  final List<PartialStackFrame> frames;

  /// The number of frames in this pattern.
  int get numFrames => frames.length;

  /// The string to replace the frames with.
  ///
  /// If the same replacement string is used multiple times in a row, the
  /// [FrameworkError.defaultStackFilter] will insert a repeat count after this
  /// line rather than repeating it.
  final String replacement;

  List<String> get _replacements => List<String>.filled(numFrames, replacement);

  @override
  void filter(List<StackFrame> stackFrames, List<String?> reasons) {
    for (var index = 0; index < stackFrames.length - numFrames; index += 1) {
      if (_matchesFrames(stackFrames.skip(index).take(numFrames).toList())) {
        reasons.setRange(index, index + numFrames, _replacements);
        index += numFrames - 1;
      }
    }
  }

  bool _matchesFrames(List<StackFrame> stackFrames) {
    if (stackFrames.length < numFrames) {
      return false;
    }
    for (var index = 0; index < stackFrames.length; index++) {
      if (!frames[index].matches(stackFrames[index])) {
        return false;
      }
    }
    return true;
  }
}

abstract class _ErrorDiagnostic extends DiagnosticsProperty<List<Object>> {
  /// This constructor provides a reliable hook for a kernel transformer to find
  /// error messages that need to be rewritten to include object references for
  /// interactive display of errors.
  _ErrorDiagnostic(String message, {super.level = DiagnosticLevel.info})
    : super(
        null,
        <Object>[message],
        showName: false,
        showSeparator: false,
        defaultValue: null,
        style: DiagnosticsTreeStyle.flat,
      );

  /// In debug builds, a kernel transformer rewrites calls to the default
  /// constructors for [ErrorSummary], [ErrorDescription], and [ErrorHint] to
  /// use
  /// this constructor.
  //
  // ```dart
  // _ErrorDiagnostic('Element $element must be $color')
  // ```
  // Desugars to:
  // ```dart
  // _ErrorDiagnostic.fromParts(<Object>['Element ', element, ' must be ',
  // color])
  // ```
  //
  // Slightly more complex case:
  // ```dart
  // _ErrorDiagnostic('Element ${element.runtimeType} must be $color')
  // ```
  // Desugars to:
  //```dart
  // _ErrorDiagnostic.fromParts(<Object>[
  //   'Element ',
  //   DiagnosticsProperty(null, element, description:
  // element.runtimeType?.toString()),
  //   ' must be ',
  //   color,
  // ])
  // ```
  _ErrorDiagnostic._fromParts(
    List<Object> messageParts, {
    super.style = DiagnosticsTreeStyle.flat,
    super.level = DiagnosticLevel.info,
  }) : super(
         null,
         messageParts,
         showName: false,
         showSeparator: false,
         defaultValue: null,
       );

  @override
  String toString({
    TextTreeConfiguration? parentConfiguration,
    DiagnosticLevel minLevel = DiagnosticLevel.info,
  }) {
    return valueToString(parentConfiguration: parentConfiguration);
  }

  @override
  List<Object> get value => super.value!;

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    return value.join();
  }
}

/// An explanation of the problem and its cause, any information that may help
/// track down the problem, background information, etc.
///
/// Use [ErrorDescription] for any part of an error message where neither
/// [ErrorSummary] or [ErrorHint] is appropriate.
///
/// In debug builds, values interpolated into the `message` are
/// expanded and placed into [value], which is of type [List<Object>].
/// This allows IDEs to examine values interpolated into error messages.
///
/// See also:
///
///  * [ErrorSummary], which provides a short (one line) description of the
///    problem that was detected.
///  * [ErrorHint], which provides specific, non-obvious advice that may be
///    applicable.
///  * [ErrorSpacer], which renders as a blank line.
///  * [FrameworkError], which is the most common place to use an
///    [ErrorDescription].
class ErrorDescription extends _ErrorDiagnostic {
  /// A lint enforces that this constructor can only be called with a string
  /// literal to match the limitations of the Dart Kernel transformer that
  /// optionally extracts out objects referenced using string interpolation in
  /// the message passed in.
  ///
  /// The message will display with the same text regardless of whether the
  /// kernel transformer is used. The kernel transformer is required so that
  /// debugging tools can provide interactive displays of objects described by
  /// the error.
  ErrorDescription(super.message) : super(level: DiagnosticLevel.info);

  /// Calls to the default constructor may be rewritten to use this constructor
  /// in debug mode using a kernel transformer.
  // ignore: unused_element
  ErrorDescription._fromParts(super.messageParts)
    : super._fromParts(level: DiagnosticLevel.info);
}

/// A short (one line) description of the problem that was detected.
///
/// Error summaries from the same source location should have little variance,
/// so that they can be recognized as related. For example, they shouldn't
/// include hash codes.
///
/// A [FrameworkError] must start with an [ErrorSummary] and may not contain
/// multiple summaries.
///
/// In debug builds, values interpolated into the `message` are
/// expanded and placed into [value], which is of type [List<Object>].
/// This allows IDEs to examine values interpolated into error messages.
///
/// See also:
///
///  * [ErrorDescription], which provides an explanation of the problem and its
///    cause, any information that may help track down the problem, background
///    information, etc.
///  * [ErrorHint], which provides specific, non-obvious advice that may be
///    applicable.
///  * [FrameworkError], which is the most common place to use an [ErrorSummary].
class ErrorSummary extends _ErrorDiagnostic {
  /// A lint enforces that this constructor can only be called with a string
  /// literal to match the limitations of the Dart Kernel transformer that
  /// optionally extracts out objects referenced using string interpolation in
  /// the message passed in.
  ///
  /// The message will display with the same text regardless of whether the
  /// kernel transformer is used. The kernel transformer is required so that
  /// debugging tools can provide interactive displays of objects described by
  /// the error.
  ErrorSummary(super.message) : super(level: DiagnosticLevel.summary);

  /// Calls to the default constructor may be rewritten to use this constructor
  /// in debug mode using a kernel transformer.
  // ignore: unused_element
  ErrorSummary._fromParts(super.messageParts)
    : super._fromParts(level: DiagnosticLevel.summary);
}

/// An [ErrorHint] provides specific, non-obvious advice that may be applicable.
///
/// If your message provides obvious advice that is always applicable, it is an
/// [ErrorDescription] not a hint.
///
/// In debug builds, values interpolated into the `message` are
/// expanded and placed into [value], which is of type [List<Object>].
/// This allows IDEs to examine values interpolated into error messages.
///
/// See also:
///
///  * [ErrorSummary], which provides a short (one line) description of the
///    problem that was detected.
///  * [ErrorDescription], which provides an explanation of the problem and its
///    cause, any information that may help track down the problem, background
///    information, etc.
///  * [ErrorSpacer], which renders as a blank line.
///  * [FrameworkError], which is the most common place to use an [ErrorHint].
class ErrorHint extends _ErrorDiagnostic {
  /// A lint enforces that this constructor can only be called with a string
  /// literal to match the limitations of the Dart Kernel transformer that
  /// optionally extracts out objects referenced using string interpolation in
  /// the message passed in.
  ///
  /// The message will display with the same text regardless of whether the
  /// kernel transformer is used. The kernel transformer is required so that
  /// debugging tools can provide interactive displays of objects described by
  /// the error.
  ErrorHint(super.message) : super(level: DiagnosticLevel.hint);

  /// Calls to the default constructor may be rewritten to use this constructor
  /// in debug mode using a kernel transformer.
  // ignore: unused_element
  ErrorHint._fromParts(super.messageParts)
    : super._fromParts(level: DiagnosticLevel.hint);
}

/// An [ErrorSpacer] creates an empty [DiagnosticsNode], that can be used to
/// tune the spacing between other [DiagnosticsNode] objects.
class ErrorSpacer extends DiagnosticsProperty<void> {
  /// Creates an empty space to insert into a list of [DiagnosticsNode] objects
  /// typically within a [FrameworkError] object.
  ErrorSpacer() : super('', null, description: '', showName: false);
}
