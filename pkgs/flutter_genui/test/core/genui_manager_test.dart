// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_genui/src/core/core_catalog.dart';
import 'package:flutter_genui/src/core/genui_manager.dart';
import 'package:flutter_genui/src/model/chat_message.dart';
import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_ai_client.dart';

void main() {
  group('$GenUiManager', () {
    late GenUiManager manager;
    late FakeAiClient fakeAiClient;

    setUp(() {
      fakeAiClient = FakeAiClient();
      manager = GenUiManager.conversation(
        catalog: coreCatalog,
        llmConnection: fakeAiClient,
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test(
      'sendUserPrompt adds message and calls AI, updates with response',
      () async {
        const prompt = 'Hello';
        fakeAiClient.response = {'responseText': 'Hi back'};

        final chatHistoryCompleter = Completer<List<ChatMessage>>();
        manager.uiDataStream.listen((data) {
          if (data.length == 2 && !chatHistoryCompleter.isCompleted) {
            chatHistoryCompleter.complete(data);
          }
        });

        manager.sendUserPrompt(prompt);

        final chatHistory = await chatHistoryCompleter.future;

        expect(chatHistory[0], isA<UserPrompt>());
        expect((chatHistory[0] as UserPrompt).text, prompt);
        expect(chatHistory[1], isA<TextResponse>());
        expect((chatHistory[1] as TextResponse).text, 'Hi back');

        expect(fakeAiClient.generateContentCallCount, 1);
        expect(
          (fakeAiClient.lastConversation.last.parts.first as TextPart).text,
          prompt,
        );
      },
    );

    test('loadingStream emits true then false during AI call', () async {
      const prompt = 'Hello';
      final completer = Completer<void>();
      fakeAiClient.response = {'responseText': 'Hi back'};
      fakeAiClient.preGenerateContent = () => completer.future;

      final loadingStates = <bool>[];
      final sub = manager.loadingStream.listen(loadingStates.add);

      manager.sendUserPrompt(prompt);
      await pumpEventQueue();
      expect(loadingStates, [true]);

      completer.complete();
      await pumpEventQueue();
      expect(loadingStates, [true, false]);

      await sub.cancel();
    });

    test('handles UI "add" action from AI', () async {
      fakeAiClient.response = {
        'actions': [
          {
            'action': 'add',
            'surfaceId': 's1',
            'definition': {
              'root': 'root',
              'widgets': [
                {
                  'id': 'root',
                  'widget': {
                    'text': {'text': 'UI Content'},
                  },
                },
              ],
            },
          },
        ],
      };

      final completer = Completer<List<ChatMessage>>();
      manager.uiDataStream.listen((data) {
        if (data.whereType<UiResponse>().isNotEmpty && !completer.isCompleted) {
          completer.complete(data);
        }
      });

      manager.sendUserPrompt('show me a UI');
      await pumpEventQueue();
      final chatHistory = await completer.future;

      final uiResponse = chatHistory.whereType<UiResponse>().first;
      expect(uiResponse.surfaceId, 's1');
      expect(uiResponse.definition['root'], 'root');
      expect(manager.conversationsBySurfaceId.containsKey('s1'), isTrue);
    });

    test('handles UI "update" action from AI', () async {
      // First, add a UI
      fakeAiClient.response = {
        'actions': [
          {
            'action': 'add',
            'surfaceId': 's1',
            'definition': {
              'root': 'root',
              'widgets': [
                {
                  'id': 'root',
                  'widget': {
                    'text': {'text': 'Old Content'},
                  },
                },
              ],
            },
          },
        ],
      };
      manager.sendUserPrompt('show me a UI');
      await pumpEventQueue();

      // Now, update it
      fakeAiClient.response = {
        'actions': [
          {
            'action': 'update',
            'surfaceId': 's1',
            'definition': {
              'root': 'root',
              'widgets': [
                {
                  'id': 'root',
                  'widget': {
                    'text': {'text': 'New Content'},
                  },
                },
              ],
            },
          },
        ],
      };

      final completer = Completer<List<ChatMessage>>();
      manager.uiDataStream.listen((data) {
        final uiResponses = data.whereType<UiResponse>();
        if (uiResponses.isNotEmpty) {
          final widgetDef =
              (uiResponses.first.definition['widgets'] as List<Object?>).first
                  as Map<String, Object?>;
          final textWidget = widgetDef['widget'] as Map<String, Object?>? ?? {};
          final text = textWidget['text'] as Map<String, Object?>? ?? {};
          if (text['text'] == 'New Content' && !completer.isCompleted) {
            completer.complete(data);
          }
        }
      });

      manager.sendUserPrompt('update the UI');
      await pumpEventQueue();
      final chatHistory = await completer.future;

      final uiResponse = chatHistory.whereType<UiResponse>().first;
      expect(uiResponse.surfaceId, 's1');
      final widgetDef =
          (uiResponse.definition['widgets'] as List<Object?>).first
              as Map<String, Object?>;
      final textWidget = widgetDef['widget'] as Map<String, Object?>? ?? {};
      final text = textWidget['text'] as Map<String, Object?>? ?? {};
      expect(text['text'], 'New Content');
    });

    test(
      'handles UI "delete" action from AI',
      () async {
        // First, add a UI
        fakeAiClient.response = {
          'actions': [
            {
              'action': 'add',
              'surfaceId': 's1',
              'definition': {
                'root': 'root',
                'widgets': <Map<String, Object?>>[],
              },
            },
          ],
        };

        final addCompleter = Completer<void>();
        final addSub = manager.uiDataStream.listen((data) {
          if (data.whereType<UiResponse>().isNotEmpty &&
              !addCompleter.isCompleted) {
            addCompleter.complete();
          }
        });

        manager.sendUserPrompt('show me a UI');
        await pumpEventQueue();
        await addCompleter.future;
        await addSub.cancel();
        expect(manager.conversationsBySurfaceId.containsKey('s1'), isTrue);

        // Now, delete it
        fakeAiClient.response = {
          'actions': [
            {'action': 'delete', 'surfaceId': 's1'},
          ],
        };

        final deleteCompleter = Completer<void>();
        final deleteSub = manager.uiDataStream.listen((data) {
          if (manager.conversationsBySurfaceId.isEmpty &&
              !deleteCompleter.isCompleted) {
            deleteCompleter.complete();
          }
        });

        manager.sendUserPrompt('delete the UI');
        await pumpEventQueue();
        await deleteCompleter.future;
        await deleteSub.cancel();

        expect(manager.conversationsBySurfaceId.containsKey('s1'), isFalse);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test('handles UI events and calls AI', () async {
      // Add a UI to interact with
      fakeAiClient.response = {
        'actions': [
          {
            'action': 'add',
            'surfaceId': 's1',
            'definition': {'root': 'root', 'widgets': <Map<String, Object?>>[]},
          },
        ],
      };
      final addCompleter = Completer<void>();
      final addSub = manager.uiDataStream.listen((data) {
        if (data.whereType<UiResponse>().isNotEmpty &&
            !addCompleter.isCompleted) {
          addCompleter.complete();
        }
      });

      manager.sendUserPrompt('show me a UI');
      await pumpEventQueue();
      await addCompleter.future;
      await addSub.cancel();

      // Simulate a UI event
      final event = UiActionEvent(
        surfaceId: 's1',
        widgetId: 'w1',
        eventType: 'onTap',
        timestamp: DateTime.now(),
      );
      fakeAiClient.response = {'responseText': 'event handled'};

      final eventCompleter = Completer<List<ChatMessage>>();
      final eventSub = manager.uiDataStream.listen((data) {
        // Wait for the text response from the event
        if (data.isNotEmpty &&
            data.last is TextResponse &&
            (data.last as TextResponse).text == 'event handled') {
          if (!eventCompleter.isCompleted) {
            eventCompleter.complete(data);
          }
        }
      });

      manager.handleEvents([event]);
      await pumpEventQueue();

      final chatHistory = await eventCompleter.future;
      await eventSub.cancel();

      expect(fakeAiClient.generateContentCallCount, 2);
      final lastConversation = fakeAiClient.lastConversation;
      expect(lastConversation[1].role, 'function');
      expect(
        (lastConversation.last.parts.first as TextPart).text,
        contains('user has interacted with the UI'),
      );

      expect(chatHistory.last, isA<TextResponse>());
      expect((chatHistory.last as TextResponse).text, 'event handled');
    });

    test('handles AI error gracefully', () async {
      fakeAiClient.exception = Exception('AI go boom');

      final completer = Completer<List<ChatMessage>>();
      final sub = manager.uiDataStream.listen((data) {
        if (data.isNotEmpty &&
            data.last is SystemMessage &&
            !completer.isCompleted) {
          completer.complete(data);
        }
      });

      final loadingCompleter = Completer<void>();
      final loadingSub = manager.loadingStream.listen((loading) {
        if (!loading && !loadingCompleter.isCompleted) {
          loadingCompleter.complete();
        }
      });

      manager.sendUserPrompt('break');
      await pumpEventQueue();
      final chatHistory = await completer.future;
      await sub.cancel();

      expect(chatHistory.last, isA<SystemMessage>());
      expect((chatHistory.last as SystemMessage).text, contains('Error:'));

      await loadingCompleter.future;
      await loadingSub.cancel();
    });

    test("doesn't send empty prompt", () {
      manager.sendUserPrompt('');
      expect(fakeAiClient.generateContentCallCount, 0);
    });
  });
}

// Helper to allow microtasks to run.
Future<void> pumpEventQueue() => Future<void>.delayed(Duration.zero);
