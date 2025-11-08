// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'a2a_client.dart';
library;

import 'dart:async';

/// An abstract interface for sending and receiving messages to an A2A server.
///
/// This class defines the contract for transport mechanisms that can be used
/// by the [A2AClient]. It supports both simple request-response interactions
/// and streaming communication.
abstract class Transport {
  /// Fetches a resource from the server using an HTTP GET request.
  ///
  /// Sends a GET request to the given [path] and returns the JSON-decoded
  /// response. This is typically used for non-RPC calls like fetching the
  /// agent card.
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  });

  /// Sends a single JSON-RPC request to the server and expects a single
  /// response.
  ///
  /// The [request] is a JSON-RPC 2.0 compliant [Map].
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = '/rpc',
  });

  /// Sends a JSON-RPC request to the server and returns a stream of responses.
  ///
  /// The [request] is a JSON-RPC 2.0 compliant [Map]. This method is used for
  /// streaming communication, such as with Server-Sent Events (SSE).
  Stream<Map<String, Object?>> sendStream(Map<String, Object?> request);

  /// Closes the transport and releases any underlying resources.
  void close();
}
