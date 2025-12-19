// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'a2a_client.dart';
library;

import 'dart:async';

/// Defines the contract for communication between an [A2AClient] and an A2A
/// server.
///
/// Implementations of this interface handle the low-level details of sending
/// requests and receiving responses, potentially supporting different protocols
/// like HTTP, SSE, WebSockets, etc.
abstract class Transport {
  /// Optional additional headers to be added to every request.
  Map<String, String> get authHeaders;

  /// Fetches a resource from the server using an HTTP GET request.
  ///
  /// This method is typically used for non-RPC interactions, such as retrieving
  /// the agent card from `/.well-known/agent-card.json`.
  ///
  /// The [path] is appended to the base URL of the transport. Optional
  /// [headers] can be provided for the request.
  ///
  /// Returns a [Future] that completes with the JSON-decoded response body as a
  /// `Map<String, Object?>`. Throws an `A2AException` if the request fails
  /// (e.g., network error, non-200 status).
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  });

  /// Sends a single JSON-RPC request to the server, expecting a single
  /// response.
  ///
  /// The [request] map must conform to the JSON-RPC 2.0 specification. The
  /// [path] defaults to `/rpc`, the standard endpoint for A2A JSON-RPC calls.
  ///
  /// Returns a [Future] that completes with the JSON-decoded response body. The
  /// structure of the response depends on whether the call was successful
  /// (containing a `result`) or resulted in an error (containing an `error`).
  /// Throws an `A2AException` for transport-level failures.
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = '',
    Map<String, String> headers = const {},
  });

  /// Sends a JSON-RPC request to the server and initiates a stream of
  /// responses.
  ///
  /// This method is used for long-lived connections where the server can push
  /// multiple messages to the client, such as Server-Sent Events (SSE). The
  /// [request] map must conform to the JSON-RPC 2.0 specification.
  ///
  /// Returns a [Stream] of `Map<String, Object?>`, where each map represents a
  /// JSON object received from the server. The stream may emit `A2AException`
  /// errors if issues occur during streaming.
  Stream<Map<String, Object?>> sendStream(
    Map<String, Object?> request, {
    Map<String, String> headers = const {},
  });

  /// Closes the transport and releases any underlying resources.
  ///
  /// Implementations should handle graceful shutdown of connections, like
  /// closing HTTP clients or WebSocket connections.
  void close();
}
