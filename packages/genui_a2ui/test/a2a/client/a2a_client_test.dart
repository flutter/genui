// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2ui/src/a2a/a2a.dart';
import 'package:logging/logging.dart';

import '../fakes.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  group('A2AClient', () {
    late A2AClient client;

    test('getAgentCard returns an AgentCard on success', () async {
      final Map<String, Object> agentCardJson = {
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

      final AgentCard result = await client.getAgentCard();

      expect(result.name, equals(agentCard.name));
    });

    test('messageSend returns an Event on success', () async {
      final message = const Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );
      final Map<String, Object> taskJson = {
        'kind': 'task',
        'id': '123',
        'contextId': '456',
        'status': {'state': 'submitted'},
      };

      client = A2AClient(
        url: 'http://localhost:8080',
        transport: FakeTransport(response: {'result': taskJson}),
      );

      final Task result = await client.messageSend(message);

      expect(result, isA<Task>());
      expect(result.id, equals(Task.fromJson(taskJson).id));
    });

    test('messageStream returns a stream of Events on success', () {
      final streamController = StreamController<Map<String, Object?>>();
      final event = const Event.taskStatusUpdate(
        taskId: '123',
        contextId: '456',
        status: TaskStatus(state: TaskState.working),
        final_: false,
      );

      final fakeTransport = FakeTransport(
        response: {},
        stream: streamController.stream,
      );
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: fakeTransport,
      );

      final Stream<Event> stream = client.messageStream(
        const Message(
          messageId: '1',
          role: Role.user,
          parts: [Part.text(text: 'Hello')],
        ),
      );

      expect(stream, emitsInOrder([event, emitsDone]));

      final Map<String, dynamic> json = event.toJson();
      // Workaround for missing explicitToJson in generated code
      if (json['status'] is TaskStatus) {
        json['status'] = (json['status'] as TaskStatus).toJson();
      }
      streamController.add(json);
      streamController.close();

      expect(fakeTransport.requests.length, equals(1));
      expect(fakeTransport.requests.first['id'], isNotNull);
    });

    test('request IDs are incremented for each request', () async {
      final Map<String, Object> taskJson = {
        'kind': 'task',
        'id': '123',
        'contextId': '456',
        'status': {'state': 'submitted'},
      };
      final fakeTransport = FakeTransport(response: {'result': taskJson});
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: fakeTransport,
      );

      final message = const Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );

      await client.messageSend(message);
      await client.getTask('123');
      await client.cancelTask('123');

      expect(fakeTransport.requests.length, equals(3));
      expect(fakeTransport.requests[0]['id'], equals(0));
      expect(fakeTransport.requests[1]['id'], equals(1));
      expect(fakeTransport.requests[2]['id'], equals(2));
    });

    test('messageStream handles "task" kind events by converting to '
        'TaskStatusUpdate', () {
      final streamController = StreamController<Map<String, Object?>>();
      final Map<String, Object> taskJson = {
        'kind': 'task',
        'id': '123',
        'contextId': '456',
        'status': {'state': 'working'},
      };

      final fakeTransport = FakeTransport(
        response: {},
        stream: streamController.stream,
      );
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: fakeTransport,
      );

      final Stream<Event> stream = client.messageStream(
        const Message(
          messageId: '1',
          role: Role.user,
          parts: [Part.text(text: 'Hello')],
        ),
      );

      expect(
        stream,
        emitsInOrder([
          isA<StatusUpdate>()
              .having((e) => e.taskId, 'taskId', '123')
              .having((e) => e.contextId, 'contextId', '456')
              .having((e) => e.status.state, 'status.state', TaskState.working),
          emitsDone,
        ]),
      );

      streamController.add(taskJson);
      streamController.close();
    });

    test(
      'messageStream includes extensions in params if present in message',
      () {
        final streamController = StreamController<Map<String, Object?>>();
        final fakeTransport = FakeTransport(
          response: {},
          stream: streamController.stream,
        );
        client = A2AClient(
          url: 'http://localhost:8080',
          transport: fakeTransport,
        );

        final message = const Message(
          messageId: '1',
          role: Role.user,
          parts: [Part.text(text: 'Hello')],
          extensions: ['ext1', 'ext2'],
        );

        client.messageStream(message);

        expect(fakeTransport.requests.length, equals(1));
        final Map<String, Object?> request = fakeTransport.requests.first;
        expect(request['params'], isA<Map<String, Object?>>());
        final params = request['params'] as Map<String, Object?>;
        expect(params['extensions'], equals(['ext1', 'ext2']));
      },
    );

    test('messageStream handles "status-update" kind events by converting to '
        'TaskStatusUpdate', () {
      final streamController = StreamController<Map<String, Object?>>();
      final Map<String, Object> statusUpdateJson = {
        'kind': 'status-update',
        'taskId': '123',
        'contextId': '456',
        'status': {'state': 'working'},
        'final_': false,
      };

      final fakeTransport = FakeTransport(
        response: {},
        stream: streamController.stream,
      );
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: fakeTransport,
      );

      final Stream<Event> stream = client.messageStream(
        const Message(
          messageId: '1',
          role: Role.user,
          parts: [Part.text(text: 'Hello')],
        ),
      );

      expect(
        stream,
        emitsInOrder([
          isA<StatusUpdate>()
              .having((e) => e.taskId, 'taskId', '123')
              .having((e) => e.contextId, 'contextId', '456')
              .having((e) => e.status.state, 'status.state', TaskState.working),
          emitsDone,
        ]),
      );

      streamController.add(statusUpdateJson);
      streamController.close();
    });
  });
}
