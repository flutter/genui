import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'request_handler.dart';

/// A server for handling A2A RPC calls.
class A2AServer {
  HttpServer? _server;

  /// The port the server is listening on. This is only valid after `start` has
  /// been called.
  int get port => _server?.port ?? -1;

  final Map<String, RequestHandler> _handlers = {};

  /// Creates an [A2AServer].
  A2AServer(List<RequestHandler> handlers) {
    for (final handler in handlers) {
      _handlers[handler.method] = handler;
    }
  }

  /// Starts the server.
  Future<void> start() async {
    final router = Router();

    router.post('/rpc', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final method = json['method'] as String?;
        final params = json['params'] as Map<String, dynamic>?;
        final id = json['id'];

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
            'error': {'code': -32603, 'message': 'Internal error'},
            'id': null,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await io.serve(handler, 'localhost', 0);
    print('A2A server started on ${_server!.address.host}:${_server!.port}');
    print('A2A server started on ${_server!.address.host}:${_server!.port}');
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close();
    print('A2A server stopped');
  }
}
