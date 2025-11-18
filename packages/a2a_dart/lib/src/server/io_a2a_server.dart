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

/// An A2A (Agent-to-Agent) server implementation using the `shelf` package.
///
/// This server handles A2A JSON-RPC calls, dispatching requests to the
/// appropriate [RequestHandler] based on the method name. It supports standard
/// A2A methods like task management and message sending, as well as streaming
/// responses via Server-Sent Events (SSE).
///
/// The server also provides endpoints for agent discovery via an [AgentCard].
class A2AServer {
  final Logger? _log;
  HttpServer? _server;

  /// The hostname or IP address the server will listen on.
  final String host;

  /// The port number the server is currently listening on.
  ///
  /// This property is only accurate after [start] has successfully completed.
  /// It returns -1 if the server is not running.
  int get port => _server?.port ?? -1;
  final int _requestedPort;

  final Map<String, RequestHandler> _handlers = {};

  /// The [TaskManager] instance used by the server to manage task lifecycles.
  final TaskManager taskManager;

  /// Optional middleware to be run at the beginning of the request pipeline.
  ///
  /// This is typically used for authentication, logging, or request
  /// modification before the A2A-specific middleware and handlers.
  final Middleware? initialMiddleware;

  /// The public [AgentCard] for this server.
  ///
  /// This card is returned for unauthenticated requests to
  /// `/.well-known/agent-card.json`.
  AgentCard? agentCard;

  /// An optional extended [AgentCard] for this server.
  ///
  /// If provided, this card is returned for authenticated requests to
  /// `/.well-known/agent-card.json`. If `null`, the public [agentCard] is always
  /// returned.
  AgentCard? extendedAgentCard;

  /// Creates an [A2AServer] instance.
  ///
  /// - [handlers]: A list of [RequestHandler]s to handle specific RPC methods.
  /// - [taskManager]: Manages task state and lifecycle.
  /// - [host]: The hostname or IP address to bind to (defaults to 'localhost').
  /// - [port]: The port to listen on. If 0 (default), a random available port
  ///   is chosen.
  /// - [logger]: Optional [Logger] for server-side logging.
  /// - [agentCard]: The public [AgentCard] for discovery.
  /// - [extendedAgentCard]: Optional [AgentCard] for authenticated discovery.
  /// - [initialMiddleware]: Optional middleware to run before A2A handling.
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
    // Register built-in handlers for push notification config
    registerHandler(SetPushConfigHandler(taskManager));
    registerHandler(GetPushConfigHandler(taskManager));
    registerHandler(ListPushConfigsHandler(taskManager));
    registerHandler(DeletePushConfigHandler(taskManager));
  }

  /// Registers a [RequestHandler] to handle a specific RPC method.
  ///
  /// This allows adding or overriding method handlers after the server is
  /// instantiated.
  void registerHandler(RequestHandler handler) {
    _handlers[handler.method] = handler;
  }

  /// The [Logger] used by the server for logging.
  ///
  /// Consumers can listen to the [Logger.onRecord] stream to receive log
  /// messages.
  Logger? get logger => _log;

  /// Starts the HTTP server and begins listening for incoming requests.
  ///
  /// The server will listen on the configured [host] and `_requestedPort`.
  /// If `_requestedPort` was 0, an ephemeral port will be chosen. The actual
  /// port can be retrieved using the [port] getter after the Future completes.
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

  /// Handles GET requests for the AgentCard.
  ///
  /// Serves `/.well-known/agent-card.json`. Returns [extendedAgentCard] if the
  /// request is authenticated (has an Authorization header) and
  /// [extendedAgentCard] is set, otherwise returns [agentCard].
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

  /// Handles incoming JSON-RPC requests to the `/rpc` endpoint.
  ///
  /// This method parses the JSON-RPC request, finds the appropriate
  /// [RequestHandler], performs security checks, and delegates to
  /// [_executeHandler].
  Future<Response> _handleRpcRequest(Request request) async {
    _log?.info('Received request: ${request.method} ${request.requestedUri}');

    Object? id;
    var json = request.context['a2a_body'] as Map<String, Object?>?;

    if (json == null) {
      // Fallback if initialMiddleware didn't parse the body.
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
        return _jsonRpcError(
          id: id,
          code: -32600,
          message: 'Invalid Request: Missing method or params',
        );
      }

      final handler = _handlers[method];
      if (handler == null) {
        return _jsonRpcError(
          id: id,
          code: -32601,
          message: 'Method not found: $method',
          responseCode: 404,
        );
      }

      // Security Check: Enforce handler.securityRequirements
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
      _log?.severe(
        'Unhandled server exception in _handleRpcRequest',
        exception,
        stackTrace,
      );
      return _jsonRpcError(
        id: id,
        code: -32000,
        message: 'Server exception: $exception',
        responseCode: 500,
      );
    } catch (exception, stackTrace) {
      _log?.severe(
        'Unhandled server error in _handleRpcRequest',
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

  /// Executes the handler and formats the response.
  ///
  /// Handles both [SingleResult] and [StreamResult] from the [RequestHandler].
  /// Catches exceptions and converts them to appropriate JSON-RPC error
  /// responses.
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

  /// Constructs a JSON-RPC error response.
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

  /// Stops the server and releases any held resources.
  Future<void> stop() async {
    await _server?.close();
    _log?.info('A2A server stopped');
  }
}
