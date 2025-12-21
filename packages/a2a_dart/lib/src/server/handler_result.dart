// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'request_handler.dart';
library;

import 'dart:async';

/// Represents the result of a [RequestHandler.handle] call.
///
/// This sealed class distinguishes between single, immediate responses and
/// streaming responses.
sealed class HandlerResult {}

/// Represents a single, non-streaming JSON-RPC response.
///
/// The [data] will be used as the value for the "result" field in the
/// JSON-RPC response object.
class SingleResult extends HandlerResult {
  /// The data payload to be returned in the response.
  final Map<String, Object?> data;

  /// Creates a [SingleResult] with the given [data].
  SingleResult(this.data);
}

/// Represents a streaming JSON-RPC response, typically using Server-Sent
/// Events.
///
/// The [stream] will emit multiple JSON objects over time.
class StreamResult extends HandlerResult {
  /// The stream of data to be returned in the response.
  ///
  /// Each event in the stream should be a Map representing a JSON object.
  final Stream<Map<String, Object?>> stream;

  /// Creates a [StreamResult] with the given [stream].
  StreamResult(this.stream);
}
