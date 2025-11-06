// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'a2a_exception.dart';
import 'http_transport.dart';

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
  /// provided for testing or to customize the HTTP client.
  SseTransport({required super.url, super.client, super.log});

  @override
  Stream<Map<String, dynamic>> sendStream(Map<String, dynamic> request) async* {
    final uri = Uri.parse('$url/rpc');
    final body = jsonEncode(request);
    log?.fine('Sending SSE request to $uri with body: $body');
    final httpRequest = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = body;

    try {
      final response = await client.send(httpRequest);
      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      var data = <String>[];

      await for (final line in lines) {
        log?.finer('Received SSE line: $line');
        if (line.isEmpty) {
          if (data.isNotEmpty) {
            final dataString = data.join('\n');
            data = [];
            try {
              final jsonData = jsonDecode(dataString) as Map<String, dynamic>;
              if (jsonData.containsKey('result')) {
                yield jsonData['result'] as Map<String, dynamic>;
              } else if (jsonData.containsKey('error')) {
                final error = jsonData['error'] as Map<String, dynamic>;
                throw A2AException.jsonRpc(
                  code: error['code'] as int,
                  message: error['message'] as String,
                  data: error['data'] as Map<String, dynamic>?,
                );
              }
            } catch (e) {
              throw A2AException.parsing(message: e.toString());
            }
          }
        } else if (line.startsWith('data:')) {
          data.add(line.substring(5).trim());
        } else if (line.startsWith(':')) {
          // Ignore comments.
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
