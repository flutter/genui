// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'transport.dart';

/// An implementation of [Transport] that uses HTTP for communication.
///
/// This class is used for standard request-response interactions with the A2A
/// server. It does not support streaming.
class HttpTransport implements Transport {
  /// The base URL of the A2A server.
  final String url;

  /// The [http.Client] used to make requests.
  final http.Client client;

  /// Creates an [HttpTransport].
  ///
  /// The [url] is the base URL of the A2A server. An optional [client] can be
  /// provided for testing or to customize the HTTP client.
  HttpTransport({required this.url, http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> get(String path) async {
    final response = await client.get(Uri.parse('$url/$path'));

    if (response.statusCode != 200) {
      throw Exception('Failed to get agent card: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
    final response = await client.post(
      Uri.parse('$url/rpc'),
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
    throw UnimplementedError(
        'Streaming is not supported by HttpTransport. Use SseTransport instead.');
  }
}
