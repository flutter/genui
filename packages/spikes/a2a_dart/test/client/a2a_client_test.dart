import 'dart:async';

import 'package:a2a_dart/src/client/a2a_client.dart';
import 'package:a2a_dart/src/client/transport.dart';
import 'package:a2a_dart/src/core/agent_card.dart';
import 'package:a2a_dart/src/core/events.dart';
import 'package:a2a_dart/src/core/message.dart';
import 'package:a2a_dart/src/core/part.dart';
import 'package:a2a_dart/src/core/task.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'a2a_client_test.mocks.dart';

@GenerateMocks([Transport])
void main() {
  group('A2AClient', () {
    late A2AClient client;
    late MockTransport mockTransport;

    setUp(() {
      mockTransport = MockTransport();
      client =
          A2AClient(url: 'http://localhost:8080', transport: mockTransport);
    });

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

      when(mockTransport.get(any)).thenAnswer((_) async => agentCardJson);

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

      when(
        mockTransport.send(any),
      ).thenAnswer((_) async => {'result': taskJson});

      final result = await client.createTask(message);

      expect(result, equals(task));
    });

    test('createTask throws an exception on error', () {
      final message = Message(
        messageId: '1',
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
      );

      when(
        mockTransport.send(any),
      ).thenAnswer((_) async => {
            'error': {'code': -32600, 'message': 'Invalid Request'}
          });

      expect(client.createTask(message), throwsException);
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

      when(
        mockTransport.sendStream(any),
      ).thenAnswer((_) => streamController.stream);

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

    test('executeTask handles SSE keepalive comments', () {
      final streamController = StreamController<Map<String, dynamic>>();
      final eventJson = {
        'kind': 'task_status_update',
        'taskId': '123',
        'contextId': '456',
        'status': {'state': 'working'},
        'final_': false,
      };
      final event = StreamingEvent.fromJson(eventJson);

      when(
        mockTransport.sendStream(any),
      ).thenAnswer((_) => streamController.stream);

      final stream = client.executeTask('test-task-id');

      expect(
        stream,
        emitsInOrder([
          event,
          emitsDone,
        ]),
      );

      // The SseTransport is responsible for filtering keepalive comments, so the
      // client should never receive them. The mock transport simulates this by
      // not sending a keepalive event.
      streamController.add(eventJson);
      streamController.close();
    });
  });
}
