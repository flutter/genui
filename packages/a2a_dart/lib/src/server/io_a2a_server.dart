// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../core/agent_card.dart';
import 'a2a_server_exception.dart';
import 'delete_push_config_handler.dart';
import 'get_push_config_handler.dart';
import 'handler_result.dart';
import 'list_push_configs_handler.dart';
import 'request_handler.dart';
import 'set_push_config_handler.dart';
import 'task_manager.dart';

/// A server for handling A2A RPC calls.
///
/// This class provides a simple and extensible server for handling A2A RPC
/// calls based on the `shelf` package. It uses a request handler pipeline to
/// process incoming requests. Each RPC method is implemented as a
/// [RequestHandler].
///
/// The server supports both single-shot and streaming responses.
class A2AServer {
  final Logger? _log;
  HttpServer? _server;

  /// The host the server is listening on.
  final String host;

  /// The port the server is listening on.
  ///
  /// This is only valid after [start] has been called. If the server is not
  /// running, this will be -1.
  int get port => _server?.port ?? -1;
  final int _requestedPort;

  final Map<String, RequestHandler> _handlers = {};
  final TaskManager taskManager;
  final Middleware? initialMiddleware;

  /// The public agent card for this server.
  ///
  /// If this is set, the server will respond to unauthenticated requests to
  /// `/.well-known/agent-card.json` with this card.
  AgentCard? agentCard;

  /// The extended agent card for this server.
  ///
  /// This is returned when a request to `/.well-known/agent-card.json`
  /// includes an `Authorization` header. If this is not set, the public
  /// [agentCard] is returned for all requests.
  AgentCard? extendedAgentCard;

  /// Creates an [A2AServer].
  ///
  /// The [handlers] are a list of [RequestHandler]s that will be used to
  /// process incoming requests. Each handler is responsible for a single RPC
  /// method.
  ///
  /// The [host] and [port] determine where the server will listen. If [port] is
  /// 0, a random available port will be chosen.
  ///
  /// The [logger] is used for logging messages from the server. To listen to
  /// log messages, you can subscribe to the [logger]'s `onRecord` stream:
  ///
  /// ```dart
  /// final server = A2AServer([...]);
  /// server.logger?.onRecord.listen((record) {
  ///   print('${record.level.name}: ${record.time}: ${record.message}');
  /// });
  /// ```
  A2AServer(
    List<RequestHandler> handlers,
    this.taskManager, {
    this.host = 'localhost',
    int port = 0,
    Logger? logger,
    this.agentCard,
    this.extendedAgentCard,
    this.initialMiddleware,
  }) : _requestedPort = port,
       _log = logger {
    for (final handler in handlers) {
      registerHandler(handler);
    }
    registerHandler(SetPushConfigHandler(taskManager));
    registerHandler(GetPushConfigHandler(taskManager));
    registerHandler(ListPushConfigsHandler(taskManager));
    registerHandler(DeletePushConfigHandler(taskManager));
  }

  /// Registers a [RequestHandler] with the server.
  ///
  /// This can be used to add handlers after the server has been created.
  void registerHandler(RequestHandler handler) {
    _handlers[handler.method] = handler;
  }

  /// The logger used for logging messages.
  ///
  /// This can be listened to in order to receive log messages from the server.
  ///
  /// To listen to log messages from the server, you can subscribe to the
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
  /// The server will listen on the configured [host] and [port]. If the port
  /// was configured to 0, it will listen on a random available port. The actual
  /// port can be retrieved from the [port] getter after this method completes.
  Future<void> start() async {
    final router = Router()
      ..post('/rpc', _handleRpcRequest)
      ..get('/.well-known/agent-card.json', _handleAgentCardRequest);

    var pipeline = const Pipeline();
    if (initialMiddleware != null) {
      pipeline = pipeline.addMiddleware(initialMiddleware!);
    }
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

    _log?.info('Starting A2A server on $host:$_requestedPort...');
    _server = await shelf_io.serve(handler, host, _requestedPort);
    _log?.info(
      'A2A server started on ${_server!.address.host}:${_server!.port}',
    );
  }

  Future<Response> _handleAgentCardRequest(Request request) async {
    final isAuthenticated = request.headers.containsKey('Authorization');
    AgentCard? card;
    if (isAuthenticated && extendedAgentCard != null) {
      card = extendedAgentCard;
    } else {
      card = agentCard;
    }
    if (card == null) {
      return Response.notFound('Agent card not configured');
    }
    return Response.ok(
      jsonEncode(card.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleRpcRequest(Request request) async {
    _log?.info('Received request: ${request.method} ${request.requestedUri}');

    Object? id;
    var json = request.context['a2a_body'] as Map<String, Object?>?;

    if (json == null) {
      // This should not happen if the security middleware ran first for /rpc requests
      final body = await request.readAsString();
      _log?.fine('Request body: $body');
      try {
        json = jsonDecode(body) as Map<String, Object?>;
      } on FormatException {
        return _jsonRpcError(id: null, code: -32700, message: 'Parse error');
      }
    }

    try {
      id = json['id'];
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
      // Security Check
      final securityRequirements = handler.securityRequirements;
      if (securityRequirements != null && securityRequirements.isNotEmpty) {
        final authContext =
            request.context['a2a_auth'] as Map<String, dynamic>?;

        if (authContext == null || authContext['isAuthenticated'] != true) {
          return _jsonRpcError(
            id: id,
            code: -32002,
            message: 'Unauthorized: Missing or failed authentication.',
            responseCode: 401,
          );
        }

        final authenticatedSchemes =
            authContext['schemes'] as Map<String, List<String>>? ?? {};
        var authorized = false;
        for (final requirement in securityRequirements) {
          var requirementMet = true;
          for (final schemeName in requirement.keys) {
            final requiredScopes = requirement[schemeName]!;
            if (!authenticatedSchemes.containsKey(schemeName)) {
              requirementMet = false;
              break;
            }
            final grantedScopes = authenticatedSchemes[schemeName]!;
            if (!requiredScopes.every(grantedScopes.contains)) {
              requirementMet = false;
              break;
            }
          }
          if (requirementMet) {
            authorized = true;
            break;
          }
        }

        if (!authorized) {
          return _jsonRpcError(
            id: id,
            code: -32002,
            message: 'Unauthorized: Insufficient permissions for this method.',
            responseCode: 401,
          );
        }
      }

      return _executeHandler(handler, params, id);
    } on Exception catch (exception, stackTrace) {
      _log?.severe('Unhandled server exception', exception, stackTrace);
      return _jsonRpcError(
        id: id,
        code: -32000,
        message: 'Server exception: $exception',
        responseCode: 500,
      );
    } catch (exception, stackTrace) {
      _log?.severe('Unhandled server error', exception, stackTrace);
      return _jsonRpcError(
        id: id,
        code: -32000,
        message: 'Server error: $exception\n$stackTrace',
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
            final json = jsonEncode({
              'jsonrpc': '2.0',
              'result': event,
              'id': id,
            });
            return utf8.encode('data: $json\n\n');
          }),
          headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        ),
      };
    } on A2AServerException catch (exception) {
      return _jsonRpcError(
        id: id,
        code: exception.code,
        message: exception.message,
        responseCode: 500,
      );
    } on Exception catch (exception, stackTrace) {
      _log?.severe(
        'Unhandled server exception in ${handler.method}',
        exception,
        stackTrace,
      );
      return _jsonRpcError(
        id: id,
        code: -32000,
        message: 'Server exception: $exception\n$stackTrace',
        responseCode: 500,
      );
    } catch (exception, stackTrace) {
      _log?.severe(
        'Unhandled server error in ${handler.method}',
        exception,
        stackTrace,
      );
      return _jsonRpcError(
        id: id,
        code: -32000,
        message: 'Server error: $exception\n$stackTrace',
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

  /// Stops the server and closes all active connections.
  Future<void> stop() async {
    await _server?.close();
    _log?.info('A2A server stopped');
  }
}
