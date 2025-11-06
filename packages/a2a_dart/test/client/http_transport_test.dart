// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../fakes.dart';

void main() {
  group('HttpTransport', () {
    test('send returns a Map on success', () async {
      final response = {
        'result': {'message': 'success'}
      };
      final transport = HttpTransport(
        url: 'http://localhost:8080',
        client: FakeHttpClient(response: response),
        log: Logger('HttpTransport'),
      );

      final result = await transport.send({});

      expect(result, equals(response));
    });
  });
}
