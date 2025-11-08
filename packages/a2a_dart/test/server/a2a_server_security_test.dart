// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../fakes.dart';

class SecuredHandler implements RequestHandler {
  @override
  String get method => 'secured/method';

  final List<Map<String, List<String>>>? _securityRequirements;

  SecuredHandler({List<Map<String, List<String>>>? securityRequirements})
    : _securityRequirements = securityRequirements;

  @override
  List<Map<String, List<String>>>? get securityRequirements =>
      _securityRequirements;

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) {
    return SingleResult({'success': true});
  }
}

// Middleware to inject a2a_auth context for testing
Middleware injectAuthContext(Map<String, dynamic>? authContext) {
  return (Handler innerHandler) {
    return (Request request) {
      final newContext = Map<String, dynamic>.from(request.context);
      if (authContext != null) {
        newContext['a2a_auth'] = authContext;
      }
      return innerHandler(request.change(context: newContext));
    };
  };
}

void main() {
  group('A2AServer Security Context Checks', () {
    late A2AServer server;
    late int port;
    final taskManager = FakeTaskManager();
    final agentCard = const AgentCard(
      protocolVersion: '0.1.0',
      name: 'Test Agent',
      description: 'Test',
      url: '',
      version: '0.0.1',
      capabilities: AgentCapabilities(),
      defaultInputModes: [],
      defaultOutputModes: [],
      skills: [],
      securitySchemes: {
        'schemeA': SecurityScheme.apiKey(name: 'X-API-KEY', in_: 'header'),
        'schemeB': SecurityScheme.http(scheme: 'bearer'),
      },
    );

    Future<void> startServer({
      required RequestHandler handler,
      Map<String, dynamic>? authContext,
    }) async {
      server = A2AServer(
        [handler],
        taskManager,
        agentCard: agentCard,
        initialMiddleware: injectAuthContext(authContext),
      );
      await server.start();
      port = server.port;
    }

    tearDown(() async {
      await server.stop();
    });

    final testRpcBody = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'secured/method',
      'params': <String, Object?>{},
      'id': 1,
    });

    test('allows handler with no security requirements', () async {
      await startServer(handler: SecuredHandler(), authContext: null);
      final response = await http.post(
        Uri.parse('http://localhost:$port/rpc'),
        body: testRpcBody,
      );
      expect(response.statusCode, 200);
    });

    test('denies if security required but no authContext', () async {
      await startServer(
        handler: SecuredHandler(
          securityRequirements: [
            {'schemeA': <String>[]},
          ],
        ),
        authContext: null,
      );
      final response = await http.post(
        Uri.parse('http://localhost:$port/rpc'),
        body: testRpcBody,
      );
      expect(response.statusCode, 401);
      final body = jsonDecode(response.body) as Map<String, Object?>;
      expect(
        (body['error'] as Map<String, Object?>)['message'],
        contains('Missing or failed authentication'),
      );
    });

    test('denies if authContext shows not authenticated', () async {
      await startServer(
        handler: SecuredHandler(
          securityRequirements: [
            {'schemeA': <String>[]},
          ],
        ),
        authContext: {'isAuthenticated': false},
      );
      final response = await http.post(
        Uri.parse('http://localhost:$port/rpc'),
        body: testRpcBody,
      );
      expect(response.statusCode, 401);
    });

    test('denies if required scheme not in authContext', () async {
      await startServer(
        handler: SecuredHandler(
          securityRequirements: [
            {'schemeA': <String>[]},
          ],
        ),
        authContext: {
          'isAuthenticated': true,
          'schemes': <String, List<String>>{'schemeB': []},
        },
      );
      final response = await http.post(
        Uri.parse('http://localhost:$port/rpc'),
        body: testRpcBody,
      );
      expect(response.statusCode, 401);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(
        (body['error'] as Map<String, Object?>)['message'],
        contains('Insufficient permissions'),
      );
    });

    test('denies if required scope not granted', () async {
      await startServer(
        handler: SecuredHandler(
          securityRequirements: [
            {
              'schemeB': ['read'],
            },
          ],
        ),
        authContext: {
          'isAuthenticated': true,
          'schemes': <String, List<String>>{
            'schemeB': ['write'],
          },
        },
      );
      final response = await http.post(
        Uri.parse('http://localhost:$port/rpc'),
        body: testRpcBody,
      );
      expect(response.statusCode, 401);
    });

    test('allows if scheme and scopes match', () async {
      await startServer(
        handler: SecuredHandler(
          securityRequirements: [
            {
              'schemeB': ['read'],
            },
          ],
        ),
        authContext: {
          'isAuthenticated': true,
          'schemes': <String, List<String>>{
            'schemeB': ['read', 'write'],
          },
        },
      );
      final response = await http.post(
        Uri.parse('http://localhost:$port/rpc'),
        body: testRpcBody,
      );
      expect(response.statusCode, 200);
      expect((jsonDecode(response.body) as Map<String, Object?>)['result'], {
        'success': true,
      });
    });

    test('allows if one of OR requirements met', () async {
      await startServer(
        handler: SecuredHandler(
          securityRequirements: [
            {'schemeA': <String>[]}, // This one won't match
            {
              'schemeB': ['read'],
            }, // This one will match
          ],
        ),
        authContext: {
          'isAuthenticated': true,
          'schemes': <String, List<String>>{
            'schemeB': ['read'],
          },
        },
      );
      final response = await http.post(
        Uri.parse('http://localhost:$port/rpc'),
        body: testRpcBody,
      );
      expect(response.statusCode, 200);
    });
  });
}
