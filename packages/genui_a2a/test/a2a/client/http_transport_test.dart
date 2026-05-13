// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2a/src/a2a/a2a.dart';
import 'package:http/http.dart' as http;

import '../fakes.dart';

void main() {
  group('HttpTransport', () {
    test('send returns a Map on success', () async {
      final response = {
        'result': {'message': 'success'},
      };
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient(response),
      );

      final Map<String, Object?> result = await transport.send({});

      expect(result, equals(response));
    });

    test('get returns a Map on success', () async {
      final response = {'message': 'success'};
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient(response),
      );

      final Map<String, Object?> result = await transport.get('/test');

      expect(result, equals(response));
    });

    test('send throws an exception on error', () {
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient({}, statusCode: 400),
      );

      expect(transport.send({}), throwsException);
    });

    test('sendStream throws A2AException.unsupportedOperation', () {
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient({}),
      );

      expect(
        () => transport.sendStream({}),
        throwsA(isA<A2AUnsupportedOperationException>()),
      );
    });
    test('get throws A2AException.http on error status', () {
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient({}, statusCode: 404),
      );

      expect(transport.get('/test'), throwsA(isA<A2AHttpException>()));
    });

    test('get throws A2AException.network on ClientException', () {
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient(
          {},
          exceptionToThrow: http.ClientException('Network error'),
        ),
      );

      expect(transport.get('/test'), throwsA(isA<A2ANetworkException>()));
    });

    test('send throws A2AException.network on ClientException', () {
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient(
          {},
          exceptionToThrow: http.ClientException('Network error'),
        ),
      );

      expect(transport.send({}), throwsA(isA<A2ANetworkException>()));
    });

    test('send throws A2AException.parsing on FormatException', () {
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient(
          {},
          exceptionToThrow: const FormatException('Parsing error'),
        ),
      );

      expect(transport.send({}), throwsA(isA<A2AParsingException>()));
    });

    test('close calls client.close', () {
      final client = FakeHttpClient({});
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: client,
      );

      transport.close();
      expect(client.closeCalled, 1);
    });
  });
}
