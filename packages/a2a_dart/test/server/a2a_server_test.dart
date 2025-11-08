// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../fakes.dart';

class MockRequestHandler implements RequestHandler {
  @override
  String get method => 'test_method';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) {
    if (params.containsKey('throw_error')) {
      throw A2AServerException('Test error', -32001);
    }
    if (params.containsKey('stream')) {
      final controller = StreamController<Map<String, Object?>>();
      controller.add({'result': 'event1'});
      controller.add({'result': 'event2'});
      controller.close();
      return StreamResult(controller.stream);
    }
    return SingleResult({'result': 'success'});
  }
}

void main() {
  hierarchicalLoggingEnabled = true;
  group('A2AServer', () {
    late A2AServer server;

    setUp(() async {
      server = A2AServer([MockRequestHandler()], FakeTaskManager(), port: 8081);
      await server.start();
    });

    tearDown(() {
      server.stop();
    });

    test('handles valid request', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'test_method',
          'params': <String, Object?>{},
          'id': 1,
        }),
      );

      expect(response.statusCode, equals(200));
      final json = jsonDecode(response.body) as Map<String, Object?>;
      expect(
        (json['result'] as Map<String, Object?>)['result'],
        equals('success'),
      );
    });

    test('returns error for invalid method', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'invalid_method',
          'params': <String, Object?>{},
          'id': 1,
        }),
      );

      expect(response.statusCode, equals(404));
      final json = jsonDecode(response.body) as Map<String, Object?>;
      expect((json['error'] as Map<String, Object?>)['code'], equals(-32601));
    });

    test('returns error for invalid request', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: jsonEncode({'jsonrpc': '2.0', 'id': 1}),
      );

      expect(response.statusCode, equals(400));
      final json = jsonDecode(response.body) as Map<String, Object?>;
      expect((json['error'] as Map<String, Object?>)['code'], equals(-32600));
    });

    test('returns error for malformed JSON', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: 'not json',
      );

      expect(response.statusCode, equals(400));
      final json = jsonDecode(response.body) as Map<String, Object?>;
      expect((json['error'] as Map<String, Object?>)['code'], equals(-32700));
    });

    test('returns error when handler throws an exception', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'test_method',
          'params': {'throw_error': true},
          'id': 1,
        }),
      );

      expect(response.statusCode, equals(500));
      final json = jsonDecode(response.body) as Map<String, Object?>;
      expect((json['error'] as Map<String, Object?>)['code'], equals(-32001));
      expect(
        (json['error'] as Map<String, Object?>)['message'],
        equals('Test error'),
      );
    });

    test('server uses the specified host', () async {
      await server.stop();
      server = A2AServer(
        [MockRequestHandler()],
        FakeTaskManager(),
        host: '127.0.0.1',
        port: 8081,
      );
      await server.start();
      expect(server.host, equals('127.0.0.1'));
    });

    test('server uses the specified port', () async {
      await server.stop();
      server = A2AServer([MockRequestHandler()], FakeTaskManager(), port: 8081);
      await server.start();
      expect(server.port, equals(8081));
    });

    test('handles streaming requests', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'test_method',
          'params': {'stream': true},
          'id': 1,
        }),
      );

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], contains('text/event-stream'));

      final lines = response.body.split('\n\n');
      expect(lines, hasLength(3)); // Two events and a blank line

      final event1 = jsonDecode(lines[0].substring(5));
      expect(
        ((event1 as Map<String, Object?>)['result']
            as Map<String, Object?>)['result'],
        equals('event1'),
      );

      final event2 = jsonDecode(lines[1].substring(5));
      expect(
        ((event2 as Map<String, Object?>)['result']
            as Map<String, Object?>)['result'],
        equals('event2'),
      );
    });
  });
}
