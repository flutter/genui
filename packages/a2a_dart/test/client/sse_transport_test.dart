// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('SseTransport', () {
    test('handles multi-line data', () async {
      final mockHttp = MockClient((request) async {
        final stream = Stream.fromIterable(
          [
            'data: { "result": { "line1": "hello",\n',
            'data: "line2": "world" } }\n\n',
          ].map((e) => utf8.encode(e)),
        );
        final bytes = (await stream.toList()).expand((i) => i).toList();
        return http.Response.bytes(bytes, 200);
      });
      final transport = SseTransport(
        url: 'http://localhost:8080',
        client: mockHttp,
      );
      final stream = transport.sendStream({});
      expect(
        stream,
        emitsInOrder([
          {'line1': 'hello', 'line2': 'world'},
          emitsDone,
        ]),
      );
    });

    test('handles comments', () async {
      final mockHttp = MockClient((request) async {
        final stream = Stream.fromIterable(
          [
            ': this is a comment\n',
            'data: { "result": { "key": "value" } }\n\n',
          ].map((e) => utf8.encode(e)),
        );
        final bytes = (await stream.toList()).expand((i) => i).toList();
        return http.Response.bytes(bytes, 200);
      });
      final transport = SseTransport(
        url: 'http://localhost:8080',
        client: mockHttp,
      );
      final stream = transport.sendStream({});
      expect(
        stream,
        emitsInOrder([
          {'key': 'value'},
          emitsDone,
        ]),
      );
    });

    test('handles parsing errors', () async {
      final mockHttp = MockClient((request) async {
        final stream = Stream.fromIterable(
          [
            'data: { "result": { "key": "value" } }\n\n',
            'data: { "error": { "code": -32000, '
                '"message": "Server error" } }\n\n',
          ].map((e) => utf8.encode(e)),
        );
        final bytes = (await stream.toList()).expand((i) => i).toList();
        return http.Response.bytes(bytes, 200);
      });
      final transport = SseTransport(
        url: 'http://localhost:8080',
        client: mockHttp,
      );
      final stream = transport.sendStream({});
      expect(
        stream,
        emitsInOrder([
          {'key': 'value'},
          emitsError(isA<A2AException>()),
          emitsDone,
        ]),
      );
    });

    test('handles http errors', () async {
      final mockHttp = MockClient.streaming((request, body) async {
        return http.StreamedResponse(
          Stream.value([]),
          400,
          reasonPhrase: 'Bad Request',
        );
      });
      final transport = SseTransport(
        url: 'http://localhost:8080',
        client: mockHttp,
      );
      final stream = transport.sendStream({});
      expect(stream, emitsError(isA<A2AException>()));
    });

    test('handles parsing errors', () async {
      final mockHttp = MockClient((request) async {
        final stream = Stream.fromIterable(
          [
            'data: { "result": { "key": "value" } }\n\n',
            'data: not json\n\n',
          ].map((e) => utf8.encode(e)),
        );
        final bytes = (await stream.toList()).expand((i) => i).toList();
        return http.Response.bytes(bytes, 200);
      });
      final transport = SseTransport(
        url: 'http://localhost:8080',
        client: mockHttp,
      );
      final stream = transport.sendStream({});
      expect(
        stream,
        emitsInOrder([
          {'key': 'value'},
          emitsError(isA<A2AException>()),
          emitsDone,
        ]),
      );
    });
  });
}
