import 'dart:async';

/// An interface for sending and receiving messages to an A2A server.
abstract class Transport {
  /// Fetches a resource from the server.
  Future<Map<String, dynamic>> get(String path);

  /// Sends a request-response message to the server.
  Future<Map<String, dynamic>> send(Map<String, dynamic> request);

  /// Sends a streaming message to the server.
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request);
}
