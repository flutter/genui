import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'transport.dart';

/// An implementation of [Transport] that uses HTTP for communication.
class HttpTransport implements Transport {
  /// Creates an [HttpTransport].
  HttpTransport({required this.url, http.Client? client})
    : _client = client ?? http.Client();

  /// The URL of the A2A server.
  final String url;

  final http.Client _client;

  @override
  Future<Map<String, dynamic>> get(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to get resource: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request) {
    throw UnimplementedError('Streaming is not supported by HttpTransport.');
  }
}
