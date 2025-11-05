import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'request_handler.dart';

class A2AServer {
  final int port;
  final Map<String, RequestHandler> _handlers = {};
  HttpServer? _server;

  A2AServer(List<RequestHandler> handlers, {this.port = 8080}) {
    for (final handler in handlers) {
      _handlers[handler.method] = handler;
    }
  }

  Future<void> start() async {
    final router = Router();

    router.post('/rpc', (Request request) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final method = json['method'] as String?;
        final id = json['id'];

        if (method == null) {
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
          return handler.handle(request);
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

    final handler = const Pipeline().addHandler(router.call);

    _server = await io.serve(handler, 'localhost', port);
    print('A2A server started on port $port');
  }

  Future<void> stop() async {
    await _server?.close();
    print('A2A server stopped');
  }
}
