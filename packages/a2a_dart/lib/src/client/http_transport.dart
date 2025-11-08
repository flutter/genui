// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'a2a_exception.dart';
import 'transport.dart';

/// An implementation of the [Transport] interface that uses HTTP for
/// communication.
///
/// This transport is used for single-shot GET and POST requests. It does not
/// support streaming.
class HttpTransport implements Transport {
  /// The URL of the A2A server.
  final String url;

  /// The HTTP client to use for requests.
  final http.Client client;

  /// The logger to use for logging.
  final Logger? log;

  /// Creates an [HttpTransport].
  ///
  /// The [url] is the base URL of the A2A server.
  /// The [client] is an optional HTTP client to use for requests. If not
  /// provided, a new one will be created.
  /// The [log] is an optional logger.
  HttpTransport({required this.url, http.Client? client, this.log})
    : client = client ?? http.Client();

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    final uri = Uri.parse('$url$path');
    log?.fine('Sending GET request to $uri');
    final response = await client.get(uri, headers: headers);
    log?.fine('Received response from GET $uri: ${response.body}');
    if (response.statusCode != 200) {
      throw A2AException.http(
        statusCode: response.statusCode,
        reason: response.reasonPhrase,
      );
    }
    return jsonDecode(response.body) as Map<String, Object?>;
  }

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = '/rpc',
  }) async {
    final uri = Uri.parse('$url$path');
    log?.fine('Sending POST request to $uri with body: $request');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request),
    );
    log?.fine('Received response from POST $uri: ${response.body}');
    if (response.statusCode != 200) {
      throw A2AException.network(
        message:
            'Failed to send request: ${response.statusCode} ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, Object?>;
  }

  @override
  Stream<Map<String, Object?>> sendStream(Map<String, Object?> request) {
    // This transport does not support streaming.
    throw UnimplementedError('SSE is not implemented for HttpTransport');
  }

  @override
  void close() {
    client.close();
  }
}
