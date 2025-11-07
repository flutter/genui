// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'transport.dart';
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'a2a_exception.dart';
import 'http_transport.dart';
import 'sse_parser.dart';

/// An implementation of [Transport] that uses Server-Sent Events (SSE) for
/// streaming communication.
///
/// This class extends [HttpTransport] and adds support for streaming responses
/// from the server. It should be used when real-time, bidirectional
/// communication is required. For simple request-response interactions,
/// [HttpTransport] is sufficient.
class SseTransport extends HttpTransport {
  /// Creates an [SseTransport].
  ///
  /// The [url] is the base URL of the A2A server. An optional [client] can be
  /// provided for testing or to customize the HTTP client. The [log] is an
  /// optional logger.
  SseTransport({required super.url, super.client, super.log});

  @override
  Stream<Map<String, Object?>> sendStream(Map<String, Object?> request) async* {
    final uri = Uri.parse('$url/rpc');
    final body = jsonEncode(request);
    log?.fine('Sending SSE request to $uri with body: $body');
    final httpRequest = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = body;

    try {
      final response = await client.send(httpRequest);
      if (response.statusCode >= 400) {
        final body = await response.stream.bytesToString();
        log?.severe('Received error response: ${response.statusCode} $body');
        throw A2AException.http(
          statusCode: response.statusCode,
          reason: '${response.reasonPhrase} $body',
        );
      }
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      yield* SseParser(log: log).parse(lines);
    } catch (e) {
      if (e is A2AException) {
        rethrow;
      }
      throw A2AException.network(message: e.toString());
    }
  }
}
