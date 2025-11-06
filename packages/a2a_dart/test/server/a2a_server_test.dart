// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:logging/logging.dart';

class MockRequestHandler implements RequestHandler {
  @override
  String get method => 'test_method';

  @override
  FutureOr<HandlerResult> handle(Map<String, dynamic> params) {
    if (params.containsKey('throw_error')) {
      throw Exception('Test error');
    }
    return SingleResult({'result': 'success'});
  }
}

void main() {
  hierarchicalLoggingEnabled = true;
  group('A2AServer', () {
    late A2AServer server;

    setUp(() async {
      server = A2AServer([MockRequestHandler()]);
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
          'params': {},
          'id': 1,
        }),
      );

      expect(response.statusCode, equals(200));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      expect(json['result']['result'], equals('success'));
    });

    test('returns error for invalid method', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'invalid_method',
          'params': {},
          'id': 1,
        }),
      );

      expect(response.statusCode, equals(404));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      expect(json['error']['code'], equals(-32601));
    });

    test('returns error for invalid request', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
        }),
      );

      expect(response.statusCode, equals(400));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      expect(json['error']['code'], equals(-32600));
    });

    test('returns error for malformed JSON', () async {
      final response = await http.post(
        Uri.parse('http://localhost:${server.port}/rpc'),
        body: 'not json',
      );

      expect(response.statusCode, equals(400));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      expect(json['error']['code'], equals(-32700));
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
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      expect(json['error']['code'], equals(-32000));
    });

    test('server uses the specified host', () async {
      await server.stop();
      server = A2AServer([MockRequestHandler()], host: '127.0.0.1');
      await server.start();
      expect(server.host, equals('127.0.0.1'));
    });

    test('server uses the specified port', () async {
      await server.stop();
      server = A2AServer([MockRequestHandler()], port: 8081);
      await server.start();
      expect(server.port, equals(8081));
    });
  });
}
