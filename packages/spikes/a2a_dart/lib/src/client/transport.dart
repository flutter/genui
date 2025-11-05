import 'dart:async';

/// An interface for sending and receiving A2A messages.
/// An interface for sending and receiving messages to an A2A server.
abstract class Transport {
  /// Fetches a resource from the given URL.
  /// Fetches a resource from the server.
  Future<Map<String, dynamic>> get(String url);

  /// Sends a single message and returns the response.
  /// Sends a request-response message to the server.

  /// Sends a message and returns a stream of responses.
  /// Sends a streaming message to the server.
}
