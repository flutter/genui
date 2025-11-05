import 'dart:async';

import 'package:a2a_dart/src/client/a2a_client.dart';
import 'package:a2a_dart/src/client/http_transport.dart';
import 'package:a2a_dart/src/core/agent_card.dart';
import 'package:a2a_dart/src/core/message.dart';
import 'package:a2a_dart/src/core/part.dart';
import 'package:a2a_dart/src/core/task.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'a2a_client_test.mocks.dart';

@GenerateMocks([HttpTransport])
void main() {
  group('A2AClient', () {
    test('getAgentCard returns AgentCard on success', () async {
      final mockTransport = MockHttpTransport();
      final client = A2AClient(
        url: 'https://example.com/a2a',
        transport: mockTransport,
      );

      when(mockTransport.get(any)).thenAnswer(
        (_) async => {
          'protocolVersion': '1.0',
          'name': 'Test Agent',
          'description': 'An agent for testing',
          'url': 'https://example.com/agent',
          'preferredTransport': 'JSONRPC',
          'version': '1.0.0',
          'capabilities': {
            'streaming': false,
            'pushNotifications': false,
            'stateTransitionHistory': false,
            'extensions': [],
          },
          'defaultInputModes': ['text/plain'],
          'defaultOutputModes': ['text/plain'],
          'skills': [],
        },
      );

      final agentCard = await client.getAgentCard();

      expect(agentCard, isA<AgentCard>());
      expect(agentCard.name, equals('Test Agent'));
    });

    test('createTask returns Task on success', () async {
      final mockTransport = MockHttpTransport();
      final client = A2AClient(
        url: 'https://example.com/a2a',
        transport: mockTransport,
      );
      final message = Message(
        messageId: '1',
        role: Role.user,
        parts: [TextPart(text: 'Hello')],
      );

      when(mockTransport.send(any)).thenAnswer(
        (_) async => {
          'jsonrpc': '2.0',
          'result': {
            'id': '123',
            'contextId': '456',
            'status': {'state': 'submitted'},
          },
          'id': 1,
        },
      );

      final task = await client.createTask(message);

      expect(task, isA<Task>());
      expect(task.id, equals('123'));
    });

    test('executeTask returns a stream of Messages on success', () {
      final mockTransport = MockHttpTransport();
      final client = A2AClient(
        url: 'https://example.com/a2a',
        transport: mockTransport,
      );
      final message = Message(
        messageId: '1',
        role: Role.user,
        parts: [TextPart(text: 'Hello')],
      );
      final streamController = StreamController<Map<String, dynamic>>();

      when(
        mockTransport.sendStream(any),
      ).thenAnswer((_) => streamController.stream);

      final stream = client.executeTask(message);

      expect(
        stream,
        emitsInOrder([
          isA<Message>().having((m) => m.messageId, 'messageId', '2'),
          isA<Message>().having((m) => m.messageId, 'messageId', '3'),
          emitsDone,
        ]),
      );

      streamController.add({
        'jsonrpc': '2.0',
        'result': {
          'messageId': '2',
          'role': 'agent',
          'parts': [
            {'kind': 'text', 'text': 'Hi there!'},
          ],
        },
        'id': 1,
      });
      streamController.add({
        'jsonrpc': '2.0',
        'result': {
          'messageId': '3',
          'role': 'agent',
          'parts': [
            {'kind': 'text', 'text': 'How can I help?'},
          ],
        },
        'id': 1,
      });
      streamController.close();
    });
  });
}
