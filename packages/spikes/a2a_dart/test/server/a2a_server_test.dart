import 'dart:async';
import 'dart:convert';

import 'package:a2a_dart/src/server/a2a_server.dart';
import 'package:a2a_dart/src/server/request_handler.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class MockRequestHandler implements RequestHandler {
  @override
  String get method => 'test_method';

  @override
  FutureOr<Map<String, dynamic>> handle(Map<String, dynamic> params) {
    return {'result': 'success'};
  }
}

void main() {
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
        Uri.parse('http://localhost:8080/rpc'),
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
        Uri.parse('http://localhost:8080/rpc'),
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
        Uri.parse('http://localhost:8080/rpc'),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
        }),
      );

      expect(response.statusCode, equals(400));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      expect(json['error']['code'], equals(-32600));
    });
  });
}
