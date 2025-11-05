import 'dart:convert';

import 'package:http/http.dart' as http;

import 'transport.dart';

/// An implementation of [Transport] that uses HTTP for communication.
class HttpTransport implements Transport {
  /// The URL of the A2A server.
  final String url;

  final http.Client _client;

  /// Creates an [HttpTransport].
  HttpTransport({required this.url, http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client.get(Uri.parse('$url/$path'));

    if (response.statusCode != 200) {
      throw Exception('Failed to get agent card: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
    final response = await _client.post(
      Uri.parse(url),
      body: jsonEncode(request),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  @override
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request) {
    // HTTP transport does not support streaming.
    throw UnimplementedError('Streaming is not supported by HttpTransport.');
  }
}
