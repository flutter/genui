// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../a2a_dart.dart' show RequestHandler;

import 'request_handler.dart' show RequestHandler;

/// A sealed class representing the result of a [RequestHandler].
sealed class HandlerResult {}

/// A [HandlerResult] that represents a single, non-streaming response.
class SingleResult extends HandlerResult {
  /// The data to be returned in the response.
  final Map<String, Object?> data;

  /// Creates a [SingleResult] with the given [data].
  SingleResult(this.data);
}

/// A [HandlerResult] that represents a streaming response.
class StreamResult extends HandlerResult {
  /// The stream of data to be returned in the response.
  final Stream<Map<String, Object?>> stream;

  /// Creates a [StreamResult] with the given [stream].
  StreamResult(this.stream);
}
