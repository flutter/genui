// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui_a2a/genui_a2a.dart';
import 'package:genui_a2a/src/a2a/a2a.dart' as a2a;

import 'fakes.dart';

void main() {
  group('A2uiAgentConnector', () {
    late A2uiAgentConnector connector;
    late FakeA2AClient fakeClient;

    setUp(() {
      fakeClient = FakeA2AClient();
      connector = A2uiAgentConnector(client: fakeClient);
    });

    tearDown(() {
      connector.dispose();
    });

    test('getAgentCard returns correct card', () async {
      fakeClient.agentCard = const a2a.AgentCard(
        name: 'Test Agent',
        description: 'A test agent',
        version: '1.0.0',
        protocolVersion: '0.1.0',
        url: 'http://localhost:8080',
        capabilities: a2a.AgentCapabilities(),
        defaultInputModes: ['text/plain'],
        defaultOutputModes: ['text/plain'],
        skills: [],
      );

      final AgentCard agentCard = await connector.getAgentCard();

      expect(agentCard.name, 'Test Agent');
      expect(agentCard.description, 'A test agent');
      expect(agentCard.version, '1.0.0');
      expect(fakeClient.getAgentCardCalled, 1);
    });

    test('connectAndSend includes clientCapabilities in metadata', () async {
      const capabilities = genui.A2UiClientCapabilities(
        supportedCatalogIds: ['cat1', 'cat2'],
      );
      fakeClient.messageStreamHandler = (_) => const Stream.empty();

      await connector.connectAndSend(
        genui.ChatMessage.user('Hi'),
        clientCapabilities: capabilities,
      );

      expect(fakeClient.messageStreamCalled, 1);
      final a2a.Message sentMessage = fakeClient.lastMessageStreamParams!;
      expect(sentMessage.metadata, isNotNull);
      expect(sentMessage.metadata!['a2uiClientCapabilities'], {
        'v0.9': {
          'supportedCatalogIds': ['cat1', 'cat2'],
        },
      });
    });

    test('connectAndSend processes stream and returns text response', () async {
      final responses = <a2a.Event>[
        const a2a.Event.taskStatusUpdate(
          taskId: 'task1',
          contextId: 'context1',
          status: a2a.TaskStatus(
            state: a2a.TaskState.working,
            message: a2a.Message(
              messageId: 'msg1',
              role: a2a.Role.agent,
              parts: [
                a2a.Part.data(
                  data: {
                    'version': 'v0.9',
                    'updateComponents': {
                      'surfaceId': 's1',
                      'components': [
                        {
                          'id': 'c1',
                          'component': 'Column',
                          'children': <Object?>[],
                        },
                      ],
                    },
                  },
                ),
                a2a.Part.text(text: 'Hello'),
              ],
            ),
          ),
          final_: false,
        ),
      ];
      fakeClient.messageStreamHandler = (_) => Stream.fromIterable(responses);

      final messages = <core.A2uiMessage>[];
      connector.stream.listen(messages.add);

      final userMessage = genui.ChatMessage.user(
        '',
        parts: [const genui.TextPart('Hi'), const genui.TextPart('There')],
      );
      final String? responseText = await connector.connectAndSend(userMessage);

      expect(responseText, 'Hello');
      expect(fakeClient.lastMessageStreamParams, isNotNull);
      final a2a.Message sentMessage = fakeClient.lastMessageStreamParams!;
      expect(sentMessage.parts.length, 2);
      expect((sentMessage.parts[0] as a2a.TextPart).text, 'Hi');
      expect((sentMessage.parts[1] as a2a.TextPart).text, 'There');
      expect(connector.taskId, 'task1');
      expect(connector.contextId, 'context1');
      expect(fakeClient.messageStreamCalled, 1);
      expect(messages.length, 1);
      expect(messages.first, isA<core.UpdateComponentsMessage>());
    });

    test('connectAndSend sends multiple text parts', () async {
      final responses = <a2a.Event>[
        const a2a.Event.taskStatusUpdate(
          taskId: 'task1',
          contextId: 'context1',
          status: a2a.TaskStatus(state: a2a.TaskState.working),
          final_: false,
        ),
      ];
      fakeClient.messageStreamHandler = (_) => Stream.fromIterable(responses);

      await connector.connectAndSend(
        genui.ChatMessage.user(
          '',
          parts: [const genui.TextPart('Hello'), const genui.TextPart('World')],
        ),
      );

      expect(fakeClient.messageStreamCalled, 1);
      expect(fakeClient.lastMessageStreamParams, isNotNull);
      final a2a.Message sentMessage = fakeClient.lastMessageStreamParams!;
      expect(sentMessage.parts.length, 2);
      expect((sentMessage.parts[0] as a2a.TextPart).text, 'Hello');
      expect((sentMessage.parts[1] as a2a.TextPart).text, 'World');
    });

    test('sendEvent sends correct message', () async {
      connector = A2uiAgentConnector(client: fakeClient);
      connector.taskId = 'task1';
      final Map<String, Object> event = {
        'action': 'testAction',
        'sourceComponentId': 'c1',
        'context': {'key': 'value'},
      };

      await connector.sendEvent(event);

      expect(fakeClient.messageSendCalled, 1);
      final a2a.Message sentMessage = fakeClient.lastMessageSendParams!;
      expect(sentMessage.referenceTaskIds, ['task1']);
      final dataPart = sentMessage.parts.first as a2a.DataPart;
      final Map<String, Object?> eventData = dataPart.data;
      expect(eventData['version'], 'v0.9');
      final action = eventData['action'] as Map<String, Object?>;
      expect(action['name'], 'testAction');
      expect(action['sourceComponentId'], 'c1');
      expect(action['context'], {'key': 'value'});
    });

    test('sendEvent does nothing if taskId is null', () async {
      await connector.sendEvent({});
      expect(fakeClient.messageSendCalled, 0);
    });

    test('connectAndSend handles DataPart and LinkPart in message', () async {
      fakeClient.messageStreamHandler = (_) => const Stream.empty();

      final userMessage = genui.ChatMessage.user(
        '',
        parts: [
          genui.DataPart(Uint8List.fromList([1, 2, 3]), mimeType: 'image/png'),
          genui.LinkPart(
            Uri.parse('https://example.com/file.txt'),
            mimeType: 'text/plain',
          ),
        ],
      );
      await connector.connectAndSend(userMessage);

      expect(fakeClient.messageStreamCalled, 1);
      final a2a.Message sentMessage = fakeClient.lastMessageStreamParams!;
      expect(sentMessage.parts.length, 2);
      expect(sentMessage.parts[0], isA<a2a.FilePart>());
      expect(sentMessage.parts[1], isA<a2a.FilePart>());
    });

    test('connectAndSend handles failure states in stream', () async {
      final responses = <a2a.Event>[
        const a2a.Event.taskStatusUpdate(
          taskId: 'task1',
          contextId: 'context1',
          status: a2a.TaskStatus(
            state: a2a.TaskState.failed,
            message: a2a.Message(
              role: a2a.Role.agent,
              parts: [a2a.Part.text(text: 'Error message')],
              messageId: 'msg1',
            ),
          ),
          final_: true,
        ),
      ];
      fakeClient.messageStreamHandler = (_) => Stream.fromIterable(responses);

      final errors = <Object>[];
      connector.errorStream.listen(errors.add);

      await connector.connectAndSend(genui.ChatMessage.user('Hi'));

      expect(errors.length, 1);
      expect(errors.first, contains('A2A Error: TaskState.failed'));
    });

    test('constructor with URL works', () {
      final conn = A2uiAgentConnector(url: Uri.parse('https://example.com'));
      expect(conn.client, isNotNull);
    });

    test('connectAndSend handles cancellation', () async {
      fakeClient.messageStreamHandler = (_) => const Stream.empty();
      final signal = genui.CancellationSignal();
      connector.taskId = 'task1';

      final Future<String?> future = connector.connectAndSend(
        genui.ChatMessage.user('Hi'),
        cancellationSignal: signal,
      );
      signal.cancel();

      await future;

      expect(fakeClient.cancelTaskCalled, 1);
      expect(fakeClient.lastCancelTaskId, 'task1');
    });

    test('connectAndSend processes stream with StatusUpdate', () async {
      final responses = <a2a.Event>[
        const a2a.Event.statusUpdate(
          taskId: 'task1',
          contextId: 'context1',
          status: a2a.TaskStatus(
            state: a2a.TaskState.working,
            message: a2a.Message(
              messageId: 'msg1',
              role: a2a.Role.agent,
              parts: [a2a.Part.text(text: 'Hello')],
            ),
          ),
        ),
      ];
      fakeClient.messageStreamHandler = (_) => Stream.fromIterable(responses);

      final String? responseText = await connector.connectAndSend(
        genui.ChatMessage.user('Hi'),
      );

      expect(responseText, 'Hello');
      expect(connector.taskId, 'task1');
      expect(connector.contextId, 'context1');
    });

    test('connectAndSend handles UiInteractionPart and UiPart', () async {
      fakeClient.messageStreamHandler = (_) => const Stream.empty();

      final userMessage = genui.ChatMessage.user(
        '',
        parts: [
          genui.UiInteractionPart.create('{"key": "value"}'),
          genui.UiPart.create(
            definition: genui.SurfaceDefinition(surfaceId: 'surface-1'),
          ),
        ],
      );
      await connector.connectAndSend(userMessage);

      expect(fakeClient.messageStreamCalled, 1);
      final a2a.Message sentMessage = fakeClient.lastMessageStreamParams!;
      expect(sentMessage.parts.length, 2);
      expect(sentMessage.parts[0], isA<a2a.DataPart>());
      expect(sentMessage.parts[1], isA<a2a.DataPart>());
    });

    test('dispose closes streams', () async {
      final streamDone = Completer<void>();
      final errorStreamDone = Completer<void>();
      connector.stream.listen(null, onDone: streamDone.complete);
      connector.errorStream.listen(null, onDone: errorStreamDone.complete);

      connector.dispose();

      await expectLater(streamDone.future, completes);
      await expectLater(errorStreamDone.future, completes);
    });
  });
}
