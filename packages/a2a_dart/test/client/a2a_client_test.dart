// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../fakes.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  group('A2AClient', () {
    late A2AClient client;

    test('getAgentCard returns an AgentCard on success', () async {
      final agentCardJson = {
        'protocolVersion': '0.1.0',
        'name': 'Test Agent',
        'description': 'A test agent.',
        'url': 'https://example.com/a2a',
        'version': '1.0.0',
        'capabilities': {
          'streaming': false,
          'pushNotifications': false,
          'stateTransitionHistory': false,
        },
        'defaultInputModes': <Object?>[],
        'defaultOutputModes': <Object?>[],
        'skills': <Object?>[],
      };
      final agentCard = AgentCard.fromJson(agentCardJson);
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(response: agentCardJson),
      );

      final result = await client.getAgentCard();

      expect(result.name, equals(agentCard.name));
    });

    test('messageSend returns an Event on success', () async {
      final message = const Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );
      final taskJson = {
        'kind': 'task',
        'id': '123',
        'contextId': '456',
        'status': {'state': 'submitted'},
      };

      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(response: {'result': taskJson}),
      );

      final result = await client.messageSend(message);

      expect(result, isA<Task>());
      expect(result.id, equals(Task.fromJson(taskJson).id));
    });

    test('messageSend throws an exception on error', () {
      final message = const Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(
          response: {
            'jsonrpc': '2.0',
            'error': {'code': -32600, 'message': 'Invalid Request'},
            'id': 0,
          },
        ),
      );

      expect(client.messageSend(message), throwsA(isA<A2AException>()));
    });

    test('messageStream returns a stream of StreamingEvents on success', () {
      final streamController = StreamController<Map<String, Object?>>();
      final eventJson = {
        'jsonrpc': '2.0',
        'method': 'message/stream',
        'params': {
          'kind': 'task_status_update',
          'taskId': '123',
          'contextId': '456',
          'status': {'state': 'working'},
          'final_': false,
        }
      };
      final event = Event.fromJson(eventJson['params'] as Map<String, Object?>);
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(
          response: {},
          stream: streamController.stream,
        ),
      );

      final stream = client.messageStream(
        const Message(
          messageId: '1',
          role: Role.user,
          parts: [Part.text(text: 'Hello')],
        ),
      );

      expect(stream, emitsInOrder([event, emitsDone]));

      streamController.add(eventJson);
      streamController.close();
    });
  });
}
