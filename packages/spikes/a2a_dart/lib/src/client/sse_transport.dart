import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sse_client/sse_client.dart';

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
    final client = SseClient.connect(Uri.parse('$url/rpc'));

    client.stream.listen((event) {
      print('Received SSE event: $event');
    });

    // TODO(gspencer): Implement SSE transport.
    throw UnimplementedError();
  }
}
