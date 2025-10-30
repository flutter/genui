// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a/a2a.dart' as a2a;
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_a2ui/flutter_genui_a2ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('A2uiContentGenerator', () {
    late A2uiContentGenerator contentGenerator;
    late FakeA2uiAgentConnector fakeConnector;
    late FakeA2AClient fakeA2AClient;

    setUp(() {
      fakeA2AClient = FakeA2AClient();
      fakeA2AClient.agentCard = a2a.A2AAgentCard()
        ..name = 'Test Agent'
        ..description = 'A test agent'
        ..version = '1.0.0';
      final fakeUrl = Uri.parse('http://fake.url');
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
      final future = contentGenerator.sendRequest(userMessage);
      expect(contentGenerator.isProcessing.value, isTrue);

      await future;

      expect(contentGenerator.isProcessing.value, isFalse);
      expect(fakeConnector.lastConnectAndSendChatMessage, userMessage);
    });

    test('sendRequest adds response to textResponseStream', () async {
      final userMessage = UserMessage([const TextPart('Test')]);
      final completer = Completer<String>();
      contentGenerator.textResponseStream.listen(completer.complete);

      await contentGenerator.sendRequest(userMessage);

      expect(await completer.future, 'Fake AI Response');
    });

    test('errorStream forwards errors from connector', () async {
      final completer = Completer<ContentGeneratorError>();
      contentGenerator.errorStream.listen(completer.complete);

      final testError = Exception('Test Error');
      fakeConnector.addError(testError);

      final capturedError = await completer.future;
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

      final capturedMessage = await completer.future;
      expect(capturedMessage, testMessage);
    });
    test('sendRequest with history adds an error to the stream', () async {
      final userMessage = UserMessage([const TextPart('Test')]);
      final history = [
        UserMessage([const TextPart('Old')]),
      ];
      final completer = Completer<ContentGeneratorError>();
      contentGenerator.errorStream.listen(completer.complete);

      await contentGenerator.sendRequest(userMessage, history: history);

      final capturedError = await completer.future;
      expect(capturedError.error, isA<String>());
      expect(capturedError.error as String, contains('ignores history'));
    });
  });
}
