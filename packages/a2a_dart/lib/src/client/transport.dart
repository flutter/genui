// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

/// An interface for sending and receiving messages to an A2A server.
///
/// This class defines the contract for transport mechanisms that can be used
/// by the [A2AClient]. It supports both simple request-response interactions
/// and streaming communication.
abstract class Transport {
  /// Fetches a resource from the server using an HTTP GET request.
  ///
  /// The [path] is appended to the base URL of the server.
  Future<Map<String, dynamic>> get(String path);

  /// Sends a request to the server and expects a single response.
  ///
  /// The [request] is a JSON-RPC 2.0 compliant [Map].
  Future<Map<String, dynamic>> send(Map<String, dynamic> request);

  /// Sends a request to the server and returns a stream of responses.
  ///
  /// The [request] is a JSON-RPC 2.0 compliant [Map]. This method is used for
  /// streaming communication, such as with Server-Sent Events (SSE).
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request);
}
