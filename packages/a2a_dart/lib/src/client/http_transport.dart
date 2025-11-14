// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'a2a_exception.dart';
import 'transport.dart';

/// An implementation of the [Transport] interface using standard HTTP requests.
///
/// This transport is suitable for single-shot GET requests and POST requests
/// for non-streaming JSON-RPC calls. It does not support [sendStream].
class HttpTransport implements Transport {
  /// The base URL of the target A2A server.
  final String url;

  /// The underlying [http.Client] used for making requests.
  final http.Client client;

  /// Optional logger for debugging and tracing transport activities.
  final Logger? log;

  /// Headers to be included in every request made by this transport.
  final Map<String, String> defaultHeaders;

  /// Creates an [HttpTransport] instance.
  ///
  /// The [url] is the base URL of the A2A server (e.g., `http://localhost:8000`).
  ///
  /// An optional [http.Client] can be provided, for example, for testing with a
  /// mock client. If null, a default client is created.
  ///
  /// [log] can be used to inject a [Logger].
  ///
  /// [defaultHeaders] allows specifying headers (like API keys) to be sent
  /// with every request.
  HttpTransport({
    required this.url,
    http.Client? client,
    this.log,
    this.defaultHeaders = const {},
  }) : client = client ?? http.Client();

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    final uri = Uri.parse('$url$path');
    final mergedHeaders = {...defaultHeaders, ...headers};
    log?.fine('Sending GET request to $uri with headers: $mergedHeaders');
    try {
      final response = await client.get(uri, headers: mergedHeaders);
      log?.fine('Received response from GET $uri: ${response.body}');
      if (response.statusCode >= 400) {
        throw A2AException.http(
          statusCode: response.statusCode,
          reason: response.reasonPhrase,
        );
      }
      return jsonDecode(response.body) as Map<String, Object?>;
    } on http.ClientException catch (e) {
      throw A2AException.network(message: e.toString());
    }
  }

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = '/rpc',
  }) async {
    final uri = Uri.parse('$url$path');
    log?.fine('Sending POST request to $uri with body: $request');
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...defaultHeaders,
    };
    try {
      final response = await client.post(
        uri,
        headers: mergedHeaders,
        body: jsonEncode(request),
      );
      log?.fine('Received response from POST $uri: ${response.body}');
      if (response.statusCode >= 400) {
        throw A2AException.http(
          statusCode: response.statusCode,
          reason: response.reasonPhrase,
        );
      }
      return jsonDecode(response.body) as Map<String, Object?>;
    } on http.ClientException catch (e) {
      throw A2AException.network(message: e.toString());
    } on FormatException catch (e) {
      throw A2AException.parsing(message: e.toString());
    }
  }

  @override
  Stream<Map<String, Object?>> sendStream(Map<String, Object?> request) {
    throw const A2AException.network(
      message:
          'Streaming is not supported by HttpTransport. Use SseTransport '
          'instead.',
    );
  }

  @override
  void close() {
    client.close();
  }
}
