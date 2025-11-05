import 'dart:async';

/// An interface for sending and receiving A2A messages.
abstract class Transport {
  /// Fetches a resource from the given URL.
  Future<Map<String, dynamic>> get(String url);

  /// Sends a single message and returns the response.
  Future<Map<String, dynamic>> send(Map<String, dynamic> request);

  /// Sends a message and returns a stream of responses.
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request);
}
