import 'dart:async';
import 'dart:convert';

import 'package:sse_channel/sse_channel.dart';

import 'transport.dart';

/// An implementation of [Transport] that uses Server-Sent Events (SSE) for
/// communication.
class SseTransport implements Transport {
  /// The URL of the A2A server.
  final String url;

  /// Creates an [SseTransport].
  SseTransport({required this.url});

  @override
  Future<Map<String, dynamic>> get(String path) {
    // SSE transport does not support request-response.
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) {
    // SSE transport does not support request-response.
    throw UnimplementedError();
  }

  @override
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request) {
    final channel = SseChannel.connect(Uri.parse('$url/rpc'));

    // TODO(gspencer): Implement SSE transport correctly.
    // This is a placeholder implementation.
    return channel.stream.map((event) {
      if (event.data == null) {
        return {};
      }
      final data = jsonDecode(event.data!) as Map<String, dynamic>;
      return data['result'] as Map<String, dynamic>;
    });
  }
}
