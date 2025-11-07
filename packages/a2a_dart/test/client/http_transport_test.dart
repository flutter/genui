// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:test/test.dart';

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

      final result = await transport.send({});

      expect(result, equals(response));
    });

    test('get returns a Map on success', () async {
      final response = {'message': 'success'};
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient(response),
      );

      final result = await transport.get('/test');

      expect(result, equals(response));
    });

    test('send throws an exception on error', () {
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient({}, statusCode: 400),
      );

      expect(transport.send({}), throwsException);
    });
  });
}
