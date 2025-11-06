// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// A handler for intercepting and processing A2A requests and responses.
abstract class A2AHandler {
  /// Handles the request and can modify it before it is sent.
  Future<Map<String, dynamic>> handleRequest(Map<String, dynamic> request);

  /// Handles the response and can modify it before it is returned to the
  /// caller.
  Future<Map<String, dynamic>> handleResponse(Map<String, dynamic> response);
}

/// A pipeline for executing a series of [A2AHandler]s.
class A2AHandlerPipeline {
  /// Creates an [A2AHandlerPipeline].
  A2AHandlerPipeline({required this.handlers});

  /// The list of handlers to execute.
  final List<A2AHandler> handlers;

  /// Executes the request handlers in order.
  Future<Map<String, dynamic>> handleRequest(
      Map<String, dynamic> request) async {
    var currentRequest = request;
    for (final handler in handlers) {
      currentRequest = await handler.handleRequest(currentRequest);
    }
    return currentRequest;
  }

  /// Executes the response handlers in reverse order.
  Future<Map<String, dynamic>> handleResponse(
    Map<String, dynamic> response,
  ) async {
    var currentResponse = response;
    for (final handler in handlers.reversed) {
      currentResponse = await handler.handleResponse(currentResponse);
    }
    return currentResponse;
  }
}
