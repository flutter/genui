// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'request_handler.dart';

/// A server for handling A2A RPC calls.
///
/// This class provides a simple and extensible server for handling A2A RPC
/// calls. It uses a request handler pipeline to process incoming requests.
class A2AServer {
  HttpServer? _server;

  /// The port the server is listening on.
  ///
  /// This is only valid after [start] has been called.
  int get port => _server?.port ?? -1;

  final Map<String, RequestHandler> _handlers = {};

  /// Creates an [A2AServer].
  ///
  /// The [handlers] are a list of [RequestHandler]s that will be used to
  /// process incoming requests. Each handler is responsible for a single RPC
  /// method.
  A2AServer(List<RequestHandler> handlers) {
    for (final handler in handlers) {
      _handlers[handler.method] = handler;
    }
  }

  /// Starts the server.
  ///
  /// The server will listen on a random available port.
  Future<void> start() async {
    final router = Router();

    router.post('/rpc', (Request request) async {
      Map<String, dynamic> json;
      dynamic id;
      try {
        final body = await request.readAsString();
        json = jsonDecode(body) as Map<String, dynamic>;
        id = json['id'];
      } on FormatException {
        return Response.badRequest(
          body: jsonEncode({
            'jsonrpc': '2.0',
            'error': {'code': -32700, 'message': 'Parse error'},
            'id': null,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      try {
        final method = json['method'] as String?;
        final params = json['params'] as Map<String, dynamic>?;

        if (method == null || params == null) {
          return Response.badRequest(
            body: jsonEncode({
              'jsonrpc': '2.0',
              'error': {'code': -32600, 'message': 'Invalid Request'},
              'id': id,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final handler = _handlers[method];
        if (handler != null) {
          final result = await handler.handle(params);
          if (result.containsKey('stream')) {
            final stream = result['stream'] as Stream<Map<String, dynamic>>;
            final responseStream = stream.map((event) {
              return utf8.encode(
                'data: ${jsonEncode({
                      'jsonrpc': '2.0',
                      'result': event,
                      'id': id
                    })}\n\n',
              );
            });
            return Response.ok(
              responseStream,
              headers: {
                'Content-Type': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
              },
            );
          }
          return Response.ok(
            jsonEncode({'jsonrpc': '2.0', 'result': result, 'id': id}),
            headers: {'Content-Type': 'application/json'},
          );
        } else {
          return Response.notFound(
            jsonEncode({
              'jsonrpc': '2.0',
              'error': {'code': -32601, 'message': 'Method not found'},
              'id': id,
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({
            'jsonrpc': '2.0',
            'error': {'code': -32000, 'message': 'Server error'},
            'id': id,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

    _server = await io.serve(handler, 'localhost', 0);
    print('A2A server started on ${_server!.address.host}:${_server!.port}');
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close();
    print('A2A server stopped');
  }
}
