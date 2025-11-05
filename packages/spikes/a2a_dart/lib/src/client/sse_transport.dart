import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'transport.dart';

/// An implementation of [Transport] that uses Server-Sent Events (SSE) for
/// streaming communication.
class SseTransport implements Transport {
  /// Creates an [SseTransport].
  SseTransport({required this.url, http.Client? client})
    : _client = client ?? http.Client();

  /// The URL of the A2A server.
  final String url;

  final http.Client _client;

  @override
  Future<Map<String, dynamic>> get(String url) {
    throw UnimplementedError('GET is not supported by SseTransport.');
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) {
    throw UnimplementedError(
      'Request-response is not supported by SseTransport.',
    );
  }

  @override
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request) {
    final streamController = StreamController<Map<String, dynamic>>();

    final httpRequest = http.Request('POST', Uri.parse(url));
    httpRequest.headers['Content-Type'] = 'application/json';
    httpRequest.headers['Accept'] = 'text/event-stream';
    httpRequest.body = jsonEncode(request);

    _client
        .send(httpRequest)
        .then((response) {
          response.stream
              .transform(utf8.decoder)
              .listen(
                (data) {
                  // This is a simplification. A real implementation would need to parse the SSE format.
                  final message = jsonDecode(data) as Map<String, dynamic>;
                  streamController.add(message);
                },
                onError: streamController.addError,
                onDone: streamController.close,
              );
        })
        .catchError((error, stackTrace) {
          streamController.addError(error, stackTrace);
        });

    return streamController.stream;
  }
}
