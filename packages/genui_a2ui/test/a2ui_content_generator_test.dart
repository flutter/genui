// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:genui_a2ui/src/a2a/a2a.dart' as a2a;

import 'fakes.dart';

void main() {
  group('A2uiContentGenerator', () {
    late A2uiContentGenerator contentGenerator;
    late FakeA2uiAgentConnector fakeConnector;
    late FakeA2AClient fakeA2AClient;

    setUp(() {
      fakeA2AClient = FakeA2AClient();
      fakeA2AClient.agentCard = const a2a.AgentCard(
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
      final Uri fakeUrl = Uri.parse('http://fake.url');
      fakeConnector = FakeA2uiAgentConnector(url: fakeUrl)
        ..client = fakeA2AClient;

      contentGenerator = A2uiContentGenerator(
        serverUrl: fakeUrl,
        connector: fakeConnector,
      );
    });

    tearDown(() {
      contentGenerator.dispose();
      fakeConnector.dispose();
    });

    test('sendRequest updates isProcessing', () async {
      final userMessage = UserMessage([const TextPart('Hello')]);

      expect(contentGenerator.isProcessing.value, isFalse);
      final Future<void> future = contentGenerator.sendRequest(
        userMessage,
        clientCapabilities: const A2UiClientCapabilities(
          supportedCatalogIds: ['test_catalog'],
        ),
      );
      expect(contentGenerator.isProcessing.value, isTrue);

      await future;

      expect(contentGenerator.isProcessing.value, isFalse);
      expect(fakeConnector.lastConnectAndSendChatMessage, userMessage);
    });

    test('sendRequest passes clientCapabilities to connector', () async {
      final userMessage = UserMessage([const TextPart('Test')]);
      const capabilities = A2UiClientCapabilities(
        supportedCatalogIds: ['test_catalog'],
      );

      await contentGenerator.sendRequest(
        userMessage,
        clientCapabilities: capabilities,
      );

      expect(fakeConnector.lastClientCapabilities, capabilities);
    });

    test('sendRequest adds response to textResponseStream', () async {
      final userMessage = UserMessage([const TextPart('Test')]);
      final completer = Completer<String>();
      contentGenerator.textResponseStream.listen(completer.complete);

      await contentGenerator.sendRequest(
        userMessage,
        clientCapabilities: const A2UiClientCapabilities(
          supportedCatalogIds: ['test_catalog'],
        ),
      );

      expect(await completer.future, 'Fake AI Response');
    });

    test('errorStream forwards errors from connector', () async {
      final completer = Completer<ContentGeneratorError>();
      contentGenerator.errorStream.listen(completer.complete);

      final testError = Exception('Test Error');
      fakeConnector.addError(testError);

      final ContentGeneratorError capturedError = await completer.future;
      expect(capturedError.error, testError);
    });

    test('a2uiMessageStream forwards messages from connector', () async {
      final completer = Completer<A2uiMessage>();
      contentGenerator.a2uiMessageStream.listen(completer.complete);

      final testMessage = A2uiMessage.fromJson({
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
      });
      fakeConnector.addMessage(testMessage);

      final A2uiMessage capturedMessage = await completer.future;
      expect(capturedMessage, testMessage);
    });
  });
}
