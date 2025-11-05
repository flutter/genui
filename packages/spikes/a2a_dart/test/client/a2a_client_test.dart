import 'dart:async';

import 'package:a2a_dart/src/client/a2a_client.dart';
import 'package:a2a_dart/src/client/transport.dart';
import 'package:a2a_dart/src/core/agent_card.dart';
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
      client = A2AClient(
        url: 'http://localhost:8080',
        transport: mockTransport,
      );
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
        parts: [TextPart(text: 'Hello')],
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

    test('executeTask returns a stream of Messages on success', () {
      final streamController = StreamController<Map<String, dynamic>>();
      final messageJson = {
        'messageId': '1',
        'role': 'agent',
        'parts': [
          {'kind': 'text', 'text': 'Hi there!'},
        ],
      };
      final message = Message.fromJson(messageJson);

      when(
        mockTransport.sendStream(any),
      ).thenAnswer((_) => streamController.stream);

      final stream = client.executeTask('test-task-id');

      expect(
        stream,
        emitsInOrder([
          message,
          emitsDone,
        ]),
      );

      streamController.add({'result': messageJson});
      streamController.close();
    });
  });
}
