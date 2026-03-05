// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../../logging_utils.dart';
import 'a2a_exception.dart';

/// A parser for Server-Sent Events (SSE).
///
/// This class is responsible for parsing a stream of SSE lines and converting
/// them into a stream of JSON objects. It handles multi-line data, comments,
/// and JSON-RPC errors.
class SseParser {
  /// The logger used for logging messages.
  final Logger? log;

  /// Creates an [SseParser].
  SseParser({this.log});

  /// Parses a stream of SSE lines and returns a stream of JSON objects.
  Stream<Map<String, Object?>> parse(Stream<String> lines) async* {
    var data = <String>[];

    try {
      await for (final line in lines) {
        final String lineData = line.length < 300
            ? line
            : line.substring(0, 300);
        log?.finer('Received SSE line: ${line.length} $lineData...');
        if (line.startsWith('data:')) {
          data.add(line.substring(5).trim());
        } else if (line.startsWith(':')) {
          // Ignore comments (used for keepalives)
          log?.finest('Ignoring SSE comment: $line');
        } else if (line.isEmpty) {
          // Event boundary
          if (data.isNotEmpty) {
            final Map<String, Object?>? result = _parseData(data);
            data = []; // Clear for next event
            if (result != null) {
              yield result;
            }
          }
        } else {
          log?.warning('Ignoring unexpected SSE line: $line');
        }
      }

      if (data.isNotEmpty) {
        log?.finer(
          'End of stream reached with ${data.length} lines of data pending.',
        );
        final Map<String, Object?>? result = _parseData(data);
        if (result != null) {
          yield result;
        }
      }
      // ignore: avoid_catching_errors
    } on StateError {
      throw const A2AException.parsing(message: 'Stream closed unexpectedly.');
    }
  }

  Map<String, Object?>? _parseData(List<String> data) {
    final String dataString = data.join('\n');
    if (dataString.isNotEmpty) {
      try {
        final jsonData = jsonDecode(dataString) as Map<String, Object?>;
        try {
          log?.finer(() => 'Parsed JSON: ${sanitizeLogData(jsonData)}');
        } catch (e) {
          log?.warning('Error logging parsed JSON: $e');
        }
        if (jsonData.containsKey('result')) {
          final Object? result = jsonData['result'];
          if (result != null) {
            return result as Map<String, Object?>;
          } else {
            log?.warning('Received a null result in the SSE stream.');
          }
        } else if (jsonData.containsKey('error')) {
          final error = jsonData['error'] as Map<String, Object?>;
          throw A2AException.jsonRpc(
            code: error['code'] as int,
            message: error['message'] as String,
            data: error['data'] as Map<String, Object?>?,
          );
        }
      } catch (e) {
        if (e is A2AException) rethrow;
        throw A2AException.parsing(message: e.toString());
      }
    }
    return null;
  }
}
