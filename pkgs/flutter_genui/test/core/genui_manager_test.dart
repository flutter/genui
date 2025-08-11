// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_genui/src/core/core_catalog.dart';
import 'package:flutter_genui/src/core/genui_manager.dart';
import 'package:flutter_genui/src/model/chat_message.dart';
import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_genui/test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$GenUiManager', () {
    late GenUiManager manager;
    late FakeAiClient fakeAiClient;

    setUp(() {
      fakeAiClient = FakeAiClient();
      manager = GenUiManager(catalog: coreCatalog, aiClient: fakeAiClient);
    });

    tearDown(() {
      manager.dispose();
    });

    test(
      'sendUserPrompt adds message and calls AI, updates with response',
      () async {
        const prompt = 'Hello';
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
                      'text': {'text': 'Hi back'},
                    },
                  },
                ],
              },
            },
          ],
        };

        final chatHistoryCompleter = Completer<List<ChatMessage>>();
        manager.uiDataStream.listen((data) {
          if (data.length == 2 && !chatHistoryCompleter.isCompleted) {
            chatHistoryCompleter.complete(data);
          }
        });

        await manager.sendUserPrompt(prompt);

        final chatHistory = await chatHistoryCompleter.future;

        expect(chatHistory[0], isA<UserMessage>());
        expect((chatHistory[0] as UserMessage).parts.first, isA<TextPart>());
        expect(
          ((chatHistory[0] as UserMessage).parts.first as TextPart).text,
          prompt,
        );
        expect(chatHistory[1], isA<UiResponseMessage>());

        expect(fakeAiClient.generateContentCallCount, 1);
        final lastConversation = fakeAiClient.lastConversation;
        expect(lastConversation.first, isA<UserMessage>());
        expect(
          ((lastConversation.first as UserMessage).parts.first as TextPart)
              .text,
          prompt,
        );
      },
    );

    test('loadingStream emits true then false during AI call', () async {
      const prompt = 'Hello';
      final completer = Completer<void>();
      fakeAiClient.response = {'actions': <Object>[]};
      fakeAiClient.preGenerateContent = () => completer.future;

      final loadingStates = <bool>[];
      final sub = manager.loadingStream.listen(loadingStates.add);

      unawaited(manager.sendUserPrompt(prompt));
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
        if (data.whereType<UiResponseMessage>().isNotEmpty &&
            !completer.isCompleted) {
          completer.complete(data);
        }
      });

      await manager.sendUserPrompt('show me a UI');
      await pumpEventQueue();
      final chatHistory = await completer.future;

      final uiResponse = chatHistory.whereType<UiResponseMessage>().first;
      expect(uiResponse.surfaceId, 's1');
      expect(uiResponse.definition['root'], 'root');
      expect(
        manager.chatHistoryForTesting.whereType<UiResponseMessage>().any(
          (m) => m.surfaceId == 's1',
        ),
        isTrue,
      );
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
      await manager.sendUserPrompt('show me a UI');
      await fakeAiClient.responseCompleter.future;

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

      await manager.sendUserPrompt('update the UI');
      await fakeAiClient.responseCompleter.future;

      final uiResponse = manager.chatHistoryForTesting
          .whereType<UiResponseMessage>()
          .firstWhere((m) => m.surfaceId == 's1');
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
          if (data.whereType<UiResponseMessage>().isNotEmpty &&
              !addCompleter.isCompleted) {
            addCompleter.complete();
          }
        });

        await manager.sendUserPrompt('show me a UI');
        await pumpEventQueue();
        await addCompleter.future;
        await addSub.cancel();
        expect(
          manager.chatHistoryForTesting.whereType<UiResponseMessage>().any(
            (m) => m.surfaceId == 's1',
          ),
          isTrue,
        );

        // Now, delete it
        fakeAiClient.response = {
          'actions': [
            {'action': 'delete', 'surfaceId': 's1'},
          ],
        };

        final deleteCompleter = Completer<void>();
        final deleteSub = manager.uiDataStream.listen((data) {
          if (!data.whereType<UiResponseMessage>().any(
                (m) => m.surfaceId == 's1',
              ) &&
              !deleteCompleter.isCompleted) {
            deleteCompleter.complete();
          }
        });

        await manager.sendUserPrompt('delete the UI');
        await pumpEventQueue();
        await deleteCompleter.future;
        await deleteSub.cancel();

        expect(
          manager.chatHistoryForTesting.whereType<UiResponseMessage>().any(
            (m) => m.surfaceId == 's1',
          ),
          isFalse,
        );
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
        if (data.whereType<UiResponseMessage>().isNotEmpty &&
            !addCompleter.isCompleted) {
          addCompleter.complete();
        }
      });

      await manager.sendUserPrompt('show me a UI');
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
      fakeAiClient.response = {
        'actions': [
          {
            'action': 'add',
            'surfaceId': 's2',
            'definition': {
              'root': 'root',
              'widgets': [
                {
                  'id': 'root',
                  'widget': {
                    'text': {'text': 'event handled'},
                  },
                },
              ],
            },
          },
        ],
      };

      final eventCompleter = Completer<List<ChatMessage>>();
      final eventSub = manager.uiDataStream.listen((data) {
        // Wait for the ui response from the event
        if (data.whereType<UiResponseMessage>().length > 1) {
          if (!eventCompleter.isCompleted) {
            eventCompleter.complete(data);
          }
        }
      });

      manager.handleEvents('s1', [event]);
      await pumpEventQueue();

      final chatHistory = await eventCompleter.future;
      await eventSub.cancel();

      expect(fakeAiClient.generateContentCallCount, 2);
      final lastConversation = fakeAiClient.lastConversation;
      final userMessage = lastConversation[2] as UserMessage;
      expect(userMessage.parts.first, isA<ToolResultPart>());
      expect(userMessage.parts.last, isA<ThinkingPart>());
      expect(
        (userMessage.parts.last as ThinkingPart).text,
        contains('The user has interacted with the UI surface'),
      );

      expect(chatHistory.last, isA<UiResponseMessage>());
    });

    test('handles AI error gracefully', () async {
      fakeAiClient.exception = Exception('AI go boom');

      final completer = Completer<List<ChatMessage>>();
      final sub = manager.uiDataStream.listen((data) {
        if (data.isNotEmpty &&
            data.last is AssistantMessage &&
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

      final logs = <String>[];
      await runZoned(
        () async {
          await manager.sendUserPrompt('break');
          await pumpEventQueue();
        },
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            logs.add(line);
          },
        ),
      );

      final chatHistory = await completer.future;
      await sub.cancel();

      expect(chatHistory.last, isA<AssistantMessage>());
      expect(
        ((chatHistory.last as AssistantMessage).parts.first as TextPart).text,
        contains('Error:'),
      );

      await loadingCompleter.future;
      await loadingSub.cancel();

      expect(logs.first, contains('Error generating content'));
    });

    test("doesn't send empty prompt", () async {
      await manager.sendUserPrompt('');
      expect(fakeAiClient.generateContentCallCount, 0);
    });

    test('sends user prompt and gets UI response when showInternalMessages is '
        'true', () async {
      manager = GenUiManager(
        catalog: coreCatalog,
        aiClient: fakeAiClient,
        showInternalMessages: true,
      );
      const prompt = 'Hello';
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
                    'text': {'text': 'Hi back'},
                  },
                },
              ],
            },
          },
        ],
      };

      final chatHistoryCompleter = Completer<List<ChatMessage>>();
      manager.uiDataStream.listen((data) {
        if (data.length == 2 && !chatHistoryCompleter.isCompleted) {
          chatHistoryCompleter.complete(data);
        }
      });

      await manager.sendUserPrompt(prompt);

      final chatHistory = await chatHistoryCompleter.future;

      expect(chatHistory[0], isA<UserMessage>());
      expect(
        ((chatHistory[0] as UserMessage).parts.first as TextPart).text,
        prompt,
      );
      expect(chatHistory[1], isA<UiResponseMessage>());
    });
  });
}

// Helper to allow microtasks to run.
Future<void> pumpEventQueue() => Future<void>.delayed(Duration.zero);
