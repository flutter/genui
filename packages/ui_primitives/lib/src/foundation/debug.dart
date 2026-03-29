// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:developer';
///
/// @docImport 'package:flutter/foundation.dart';
/// @docImport 'package:flutter/rendering.dart';
/// @docImport 'package:flutter/widgets.dart';
library;

import '../dart_ui/window.dart';

import 'print.dart';

export 'print.dart' show DebugPrintCallback;

/// Boolean value indicating whether [debugInstrumentAction] will instrument
/// actions in debug builds.
///
/// The framework does not use [debugInstrumentAction] internally, so this
/// does not enable any additional instrumentation for the framework itself.
///
/// See also:
///
///  * [debugProfileBuildsEnabled], which enables additional tracing of builds
///    in [Widget]s.
///  * [debugProfileLayoutsEnabled], which enables additional tracing of layout
///    events in [RenderObject]s.
///  * [debugProfilePaintsEnabled], which enables additional tracing of paint
///    events in [RenderObject]s.
bool debugInstrumentationEnabled = false;

/// Runs the specified [action], timing how long the action takes in debug
/// builds when [debugInstrumentationEnabled] is true.
///
/// The instrumentation will be printed to the logs using [debugPrint]. In
/// non-debug builds, or when [debugInstrumentationEnabled] is false, this will
/// run [action] without any instrumentation.
///
/// Returns the result of running [action].
///
/// See also:
///
///  * [Timeline], which is used to record synchronous tracing events for
///    visualization in Chrome's tracing format. This method does not
///    implicitly add any timeline events.
Future<T> debugInstrumentAction<T>(
  String description,
  Future<T> Function() action,
) async {
  var instrument = false;
  assert(() {
    instrument = debugInstrumentationEnabled;
    return true;
  }());
  if (instrument) {
    // dart format off
    // flutter_ignore: stopwatch (see analyze.dart)
    final stopwatch = Stopwatch() ..start();
    // Ignore context: The framework does not use this function internally so it
    // will not cause flakes.
    // dart format on
    try {
      return await action();
    } finally {
      stopwatch.stop();
      debugPrint('Action "$description" took ${stopwatch.elapsed}');
    }
  } else {
    return action();
  }
}

/// Configure [debugFormatDouble] using [num.toStringAsPrecision].
///
/// Defaults to null, which uses the default logic of [debugFormatDouble].
int? debugDoublePrecision;

/// Formats a double to have standard formatting.
///
/// This behavior can be overridden by [debugDoublePrecision].
String debugFormatDouble(double? value) {
  if (value == null) {
    return 'null';
  }
  if (debugDoublePrecision != null) {
    return value.toStringAsPrecision(debugDoublePrecision!);
  }
  return value.toStringAsFixed(1);
}

/// A setting that can be used to override the platform [Brightness] exposed
/// from [BindingBase.platformDispatcher].
///
/// See also:
///
///  * [WidgetsApp], which uses the [debugBrightnessOverride] setting in debug
///    mode
///    to construct a [MediaQueryData].
Brightness? debugBrightnessOverride;

/// The address for the active DevTools server used for debugging this
/// application.
String? activeDevToolsServerAddress;

/// The uri for the connected vm service protocol.
String? connectedVmServiceUri;
