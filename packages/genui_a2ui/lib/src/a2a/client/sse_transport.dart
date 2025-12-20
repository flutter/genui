// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:logging/logging.dart';
/// @docImport 'transport.dart';
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'a2a_exception.dart';
import 'http_transport.dart';
import 'sse_parser.dart';

/// A [Transport] implementation using Server-Sent Events (SSE) for streaming.
///
/// This class extends [HttpTransport] to add support for streaming responses
/// from the server via an SSE connection. It should be used for methods like
/// `message/stream` where the server pushes multiple events over time.
class SseTransport extends HttpTransport {
  /// Creates an [SseTransport] instance.
  ///
  /// Inherits parameters from [HttpTransport]:
  /// - [url]: The base URL of the A2A server.
  /// - [authHeaders]: Optional additional authorization headers.
  /// - [client]: Optional [http.Client] for custom configurations or testing.
  /// - [log]: Optional [Logger] instance.
  SseTransport({
    required super.url,
    super.authHeaders,
    super.client,
    super.log,
  });

  @override
  Stream<Map<String, Object?>> sendStream(
    Map<String, Object?> request, {
    Map<String, String> headers = const {},
  }) async* {
    final Uri uri = Uri.parse(url);
    final String body = jsonEncode(request);
    log?.fine('Sending SSE request to $uri with body: $body');
    final Map<String, String> allHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      ...authHeaders,
      ...headers,
    };
    final httpRequest = http.Request('POST', uri)
      ..headers.addAll(allHeaders)
      ..body = body;

    try {
      final http.StreamedResponse response = await client.send(httpRequest);
      if (response.statusCode >= 400) {
        final String responseBody = await response.stream.bytesToString();
        log?.severe(
          'Received error response: ${response.statusCode} $responseBody',
        );
        throw A2AException.http(
          statusCode: response.statusCode,
          reason: '${response.reasonPhrase} $responseBody',
        );
      }
      final Stream<String> lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      yield* SseParser(log: log).parse(lines);
    } on http.ClientException catch (e) {
      throw A2AException.network(message: e.toString());
    } catch (e) {
      if (e is A2AException) {
        rethrow;
      }
      // Catch any other unexpected errors during stream processing.
      throw A2AException.network(message: 'SSE stream error: $e');
    }
  }
}
