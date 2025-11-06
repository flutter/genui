// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../a2a_server_exception.dart';
import '../handler_result.dart';
import '../request_handler.dart';

/// A server for handling A2A RPC calls.
///
/// This class provides a simple and extensible server for handling A2A RPC
/// calls. It uses a request handler pipeline to process incoming requests.
class A2AServer {
  final Logger? _log;
  HttpServer? _server;

  /// The host the server is listening on.
  final String host;

  /// The port the server is listening on.
  ///
  /// This is only valid after [start] has been called.
  int get port => _server?.port ?? -1;
  final int _requestedPort;

  final Map<String, RequestHandler> _handlers = {};

  /// Creates an [A2AServer].
  ///
  /// The [handlers] are a list of [RequestHandler]s that will be used to
  /// process incoming requests. Each handler is responsible for a single RPC
  /// method.
  ///
  /// To listen to log messages from the server, you can listen to the
  /// [logger]'s `onRecord` stream:
  ///
  /// ```dart
  /// final server = A2AServer([...]);
  /// server.logger?.onRecord.listen((record) {
  ///   print('${record.level.name}: ${record.time}: ${record.message}');
  /// });
  /// ```
  A2AServer(
    List<RequestHandler> handlers, {
    this.host = 'localhost',
    int port = 0,
    Logger? logger,
  }) : _requestedPort = port,
       _log = logger {
    for (final handler in handlers) {
      registerHandler(handler);
    }
  }

  /// Registers a [RequestHandler] with the server.
  void registerHandler(RequestHandler handler) {
    _handlers[handler.method] = handler;
  }

  /// The logger used for logging messages.
  ///
  /// This can be listened to in order to receive log messages from the server.
  ///
  /// To listen to log messages from the server, you can listen to the
  /// [logger]'s `onRecord` stream:
  ///
  /// ```dart
  /// final server = A2AServer([...]);
  /// server.logger?.onRecord.listen((record) {
  ///   print('${record.level.name}: ${record.time}: ${record.message}');
  /// });
  /// ```
  Logger? get logger => _log;

  /// Starts the server.
  ///
  /// The server will listen on a random available port.
  Future<void> start() async {
    final router = Router()..post('/rpc', _handleRpcRequest);
    var pipeline = const Pipeline();
    if (_log != null) {
      pipeline = pipeline.addMiddleware(
        logRequests(
          logger: (message, isError) {
            if (isError) {
              _log.severe(message);
            } else {
              _log.info(message);
            }
          },
        ),
      );
    }
    final handler = pipeline.addHandler(router.call);

    _server = await io.serve(handler, host, _requestedPort);
    _log?.info(
      'A2A server started on ${_server!.address.host}:${_server!.port}',
    );
  }

  Future<Response> _handleRpcRequest(Request request) async {
    _log?.info('Received request: ${request.method} ${request.requestedUri}');
    final body = await request.readAsString();
    _log?.fine('Request body: $body');

    Object? id;
    Map<String, Object?> json;
    try {
      json = jsonDecode(body) as Map<String, Object?>;
      id = json['id'];
    } on FormatException {
      return _jsonRpcError(id: null, code: -32700, message: 'Parse error');
    }

    try {
      final method = json['method'] as String?;
      final params = json['params'] as Map<String, Object?>?;

      if (method == null || params == null) {
        return _jsonRpcError(id: id, code: -32600, message: 'Invalid Request');
      }

      final handler = _handlers[method];
      if (handler == null) {
        return _jsonRpcError(
          id: id,
          code: -32601,
          message: 'Method not found',
          responseCode: 404,
        );
      }
      return _executeHandler(handler, params, id);
    } catch (e) {
      return _jsonRpcError(
        id: id,
        code: -32000,
        message: 'Server error: $e',
        responseCode: 500,
      );
    }
  }

  Future<Response> _executeHandler(
    RequestHandler handler,
    Map<String, Object?> params,
    Object? id,
  ) async {
    try {
      final result = await handler.handle(params);
      _log?.info('Returning successful response for method ${handler.method}');

      return switch (result) {
        SingleResult(data: final data) => Response.ok(
          jsonEncode({'jsonrpc': '2.0', 'result': data, 'id': id}),
          headers: {'Content-Type': 'application/json'},
        ),
        StreamResult(stream: final stream) => Response.ok(
          stream.map((event) {
            return utf8.encode(
              'data: ${jsonEncode({'jsonrpc': '2.0', 'result': event, 'id': id})}\n\n',
            );
          }),
          headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        ),
      };
    } on A2AServerException catch (e) {
      return _jsonRpcError(
        id: id,
        code: e.code,
        message: e.message,
        responseCode: 500,
      );
    } catch (e, stackTrace) {
      _log?.severe('Unhandled server error', e, stackTrace);
      return _jsonRpcError(
        id: id,
        code: -32000,
        message: 'Server error: $e',
        responseCode: 500,
      );
    }
  }

  Response _jsonRpcError({
    required Object? id,
    required int code,
    required String message,
    int responseCode = 400,
  }) {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'error': {'code': code, 'message': message},
      'id': id,
    });
    final headers = {'Content-Type': 'application/json'};
    return Response(responseCode, body: body, headers: headers);
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close();
    _log?.info('A2A server stopped');
  }
}
