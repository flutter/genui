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
  final String url;

  @override
  final Map<String, String> authHeaders;

  final http.Client client;
  final Logger? log;

  /// Creates an [HttpTransport] instance.
  ///
  /// Parameters:
  /// - [url]: The base URL of the A2A server.
  /// - [authHeaders]: Optional additional headers.
  /// - [client]: Optional [http.Client] for custom configurations or testing.
  /// - [log]: Optional [Logger] instance.
  HttpTransport({
    required this.url,
    this.authHeaders = const {},
    http.Client? client,
    this.log,
  }) : client = client ?? http.Client();

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    final Uri uri = Uri.parse('$url$path');
    final Map<String, String> allHeaders = {...authHeaders, ...headers};
    log?.fine('Sending GET request to $uri with headers: $allHeaders');
    try {
      final http.Response response = await client.get(uri, headers: allHeaders);
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
    String path = '',
    Map<String, String> headers = const {},
  }) async {
    final Uri uri = Uri.parse('$url$path');
    log?.fine('Sending POST request to $uri with body: $request');
    final Map<String, String> allHeaders = {
      'Content-Type': 'application/json',
      ...authHeaders,
      ...headers,
    };
    try {
      final http.Response response = await client.post(
        uri,
        headers: allHeaders,
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
  Stream<Map<String, Object?>> sendStream(
    Map<String, Object?> request, {
    Map<String, String> headers = const {},
  }) {
    throw const A2AException.unsupportedOperation(
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
