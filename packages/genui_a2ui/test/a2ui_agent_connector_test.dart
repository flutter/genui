// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a/a2a.dart' as a2a;
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui_a2ui/genui_a2ui.dart';

import 'fakes.dart';

void main() {
  group('A2uiAgentConnector', () {
    late A2uiAgentConnector connector;
    late FakeA2AClient fakeClient;

    setUp(() {
      fakeClient = FakeA2AClient();
      connector = A2uiAgentConnector(
        url: Uri.parse('http://localhost:8080'),
        client: fakeClient,
      );
    });

    tearDown(() {
      connector.dispose();
    });

    test('getAgentCard returns correct card', () async {
      fakeClient.agentCard = a2a.A2AAgentCard()
        ..name = 'Test Agent'
        ..description = 'A test agent'
        ..version = '1.0.0';

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
      fakeClient.sendMessageStreamHandler = (_) => const Stream.empty();

      await connector.connectAndSend(
        genui.UserMessage.text('Hi'),
        clientCapabilities: capabilities,
      );

      expect(fakeClient.sendMessageStreamCalled, 1);
      final a2a.A2AMessage sentMessage =
          fakeClient.lastSendMessageParams!.message;
      expect(sentMessage.metadata, isNotNull);
      expect(sentMessage.metadata!['a2uiClientCapabilities'], {
        'supportedCatalogIds': ['cat1', 'cat2'],
      });
    });

    test('connectAndSend processes stream and returns text response', () async {
      final responses = [
        a2a.A2ASendStreamMessageSuccessResponse()
          ..result = (a2a.A2ATask()
            ..id = 'task1'
            ..contextId = 'context1'),
        a2a.A2ASendStreamMessageSuccessResponse()
          ..result = (a2a.A2AMessage()
            ..parts = [
              a2a.A2ADataPart()
                ..data = {
                  'surfaceUpdate': {
                    'surfaceId': 's1',
                    'components': [
                      {
                        'id': 'c1',
                        'component': {
                          'Column': {'children': <Object?>[]},
                        },
                      },
                    ],
                  },
                },
              a2a.A2ATextPart()..text = 'Hello',
            ]),
      ];
      fakeClient.sendMessageStreamHandler = (_) =>
          Stream.fromIterable(responses);

      final messages = <genui.A2uiMessage>[];
      connector.stream.listen(messages.add);

      final userMessage = genui.UserMessage([
        const genui.TextPart('Hi'),
        const genui.TextPart('There'),
      ]);
      final String? responseText = await connector.connectAndSend(userMessage);

      expect(responseText, 'Hello');
      expect(fakeClient.lastSendMessageParams, isNotNull);
      final a2a.A2AMessage sentMessage =
          fakeClient.lastSendMessageParams!.message;
      expect(sentMessage.parts!.length, 2);
      expect((sentMessage.parts![0] as a2a.A2ATextPart).text, 'Hi');
      expect((sentMessage.parts![1] as a2a.A2ATextPart).text, 'There');
      expect(connector.taskId, 'task1');
      expect(connector.contextId, 'context1');
      expect(fakeClient.sendMessageStreamCalled, 1);
      expect(messages.length, 1);
      expect(messages.first, isA<genui.SurfaceUpdate>());
    });

    test('connectAndSend sends multiple text parts', () async {
      final responses = [
        a2a.A2ASendStreamMessageSuccessResponse()
          ..result = (a2a.A2ATask()
            ..id = 'task1'
            ..contextId = 'context1'),
      ];
      fakeClient.sendMessageStreamHandler = (_) =>
          Stream.fromIterable(responses);

      await connector.connectAndSend(
        genui.UserMessage([
          const genui.TextPart('Hello'),
          const genui.TextPart('World'),
        ]),
      );

      expect(fakeClient.sendMessageStreamCalled, 1);
      expect(fakeClient.lastSendMessageParams, isNotNull);
      final a2a.A2AMessage sentMessage =
          fakeClient.lastSendMessageParams!.message;
      expect(sentMessage.parts!.length, 2);
      expect((sentMessage.parts![0] as a2a.A2ATextPart).text, 'Hello');
      expect((sentMessage.parts![1] as a2a.A2ATextPart).text, 'World');
    });

    test('connectAndSend handles errors', () async {
      final errorResponse = a2a.A2AJSONRPCErrorResponseSSM()
        ..isError = true
        ..error = a2a.A2AJSONRPCError();
      fakeClient.sendMessageStreamHandler = (_) => Stream.value(errorResponse);

      final errors = <Object>[];
      connector.errorStream.listen(errors.add);

      await connector.connectAndSend(genui.UserMessage.text('Hi'));

      expect(errors.length, 1);
      expect(errors.first, 'A2A Error: -1');
    });

    test('sendEvent sends correct message', () async {
      connector = A2uiAgentConnector(
        url: Uri.parse('http://localhost:8080'),
        client: fakeClient,
        contextId: 'context1',
      );
      connector.taskId = 'task1';
      final Map<String, Object> event = {
        'action': 'testAction',
        'sourceComponentId': 'c1',
        'context': {'key': 'value'},
      };

      await connector.sendEvent(event);

      expect(fakeClient.sendMessageCalled, 1);
      final a2a.A2AMessage sentMessage =
          fakeClient.lastSendMessageParams!.message;
      expect(sentMessage.referenceTaskIds, ['task1']);
      expect(sentMessage.contextId, 'context1');
      final dataPart = sentMessage.parts!.first as a2a.A2ADataPart;
      final a2uiEvent = dataPart.data['a2uiEvent'] as Map<String, Object?>;
      expect(a2uiEvent['actionName'], 'testAction');
      expect(a2uiEvent['sourceComponentId'], 'c1');
      expect(a2uiEvent['resolvedContext'], {'key': 'value'});
    });

    test('sendEvent does nothing if taskId is null', () async {
      await connector.sendEvent({});
      expect(fakeClient.sendMessageCalled, 0);
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
