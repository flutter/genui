// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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

  final Logger log;

  /// Creates an [HttpTransport].
  ///
  /// The [url] is the base URL of the A2A server. An optional [client] can be
  /// provided for testing or to customize the HTTP client.
  HttpTransport({required this.url, http.Client? client, required this.log})
      : client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$url/$path');
    log.fine('Sending GET request to $uri');
    final response = await client.get(uri);
    log.fine(
        'Received response from GET $uri: ${response.statusCode} ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to get agent card: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
    final uri = Uri.parse('$url/rpc');
    final body = jsonEncode(request);
    log.fine('Sending POST request to $uri with body: $body');
    final response = await client.post(
      uri,
      body: body,
      headers: {'Content-Type': 'application/json'},
    );
    log.fine(
        'Received response from POST $uri: ${response.statusCode} ${response.body}');

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
