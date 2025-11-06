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
        'defaultInputModes': [],
        'defaultOutputModes': [],
        'skills': [],
      };
      final agentCard = AgentCard.fromJson(agentCardJson);
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(response: agentCardJson),
        logger: Logger('A2AClient'),
      );

      final result = await client.getAgentCard();

      expect(result, equals(agentCard));
    });

    test('createTask returns a Task on success', () async {
      final message = Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );
      final taskJson = {
        'id': '123',
        'contextId': '456',
        'status': {'state': 'submitted'},
      };
      final task = Task.fromJson(taskJson);
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(response: {'result': taskJson}),
        logger: Logger('A2AClient'),
      );

      final result = await client.createTask(message);

      expect(result, equals(task));
    });

    test('createTask throws an exception on error', () {
      final message = Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(response: {
          'error': {'code': -32600, 'message': 'Invalid Request'}
        }),
        logger: Logger('A2AClient'),
      );

      expect(
        client.createTask(message),
        throwsA(isA<A2AException>()),
      );
    });

    test('executeTask returns a stream of StreamingEvents on success', () {
      final streamController = StreamController<Map<String, dynamic>>();
      final eventJson = {
        'kind': 'task_status_update',
        'taskId': '123',
        'contextId': '456',
        'status': {'state': 'working'},
        'final_': false,
      };
      final event = StreamingEvent.fromJson(eventJson);
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(
          response: {},
          streamResponse: streamController.stream,
        ),
        logger: Logger('A2AClient'),
      );

      final stream = client.executeTask('test-task-id');

      expect(
        stream,
        emitsInOrder([
          event,
          emitsDone,
        ]),
      );

      streamController.add(eventJson);
      streamController.close();
    });
  });
}
