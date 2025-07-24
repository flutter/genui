import 'package:fake_async/fake_async.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/main.dart';
import 'package:genui_client/src/ai_client/ai_client.dart';
import 'package:genui_client/src/dynamic_ui.dart';
import 'package:genui_client/src/tools/tools.dart';

void main() {
  late AiClient fakeAiClient;

  setUp(() {
    fakeAiClient = FakeAiClient();
  });

  testWidgets('GenUIHomePage shows server started status after startup',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GenUIHomePage(
        autoStartServer: true,
        aiClient: fakeAiClient,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('I can create UIs. What should I make for you?'),
        findsOneWidget);
  });

  testWidgets('DynamicUi is created and handles events',
      (WidgetTester tester) async {
    await fakeAsync((async) async {
      await tester.pumpWidget(MaterialApp(
        home: GenUIHomePage(
          autoStartServer: true,
          aiClient: fakeAiClient,
        ),
      ));
      await tester.pumpAndSettle();

      // Enter a prompt and send it.
      await tester.enterText(find.byType(TextField), 'A simple button');
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byType(DynamicUi), findsOneWidget);
      expect(find.text('Click Me'), findsOneWidget);

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      async.elapse(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Button clicked!'), findsOneWidget);
    });
  });

  testWidgets('UI shows error when AI client throws an exception',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GenUIHomePage(
        autoStartServer: true,
        aiClient: fakeAiClient,
      ),
    ));
    await tester.pumpAndSettle();

    // Enter a prompt that will cause an error.
    await tester.enterText(find.byType(TextField), 'An error');
    await tester.tap(find.byType(IconButton));
    await tester.pump();

    // Pump until the error message appears, with a timeout.
    for (var i = 0; i < 10; i++) {
      if (tester.any(find.text('Error: Exception: Something went wrong'))) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Error: Exception: Something went wrong'), findsOneWidget);
    // Also make sure that the prompt is still there.
    expect(find.text('An error'), findsOneWidget);
  });

  testWidgets('User prompt is added to chat history immediately',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GenUIHomePage(
        autoStartServer: true,
        aiClient: fakeAiClient,
      ),
    ));
    await tester.pumpAndSettle();

    // Enter a prompt and send it.
    await tester.enterText(find.byType(TextField), 'A test prompt');
    await tester.tap(find.byType(IconButton));
    await tester.pump();

    // Check that the prompt is displayed immediately.
    expect(find.text('A test prompt'), findsOneWidget);

    // Let the AI "respond".
    await tester.pumpAndSettle();

    // Check that the prompt is still there, and the response is there too.
    expect(find.text('A test prompt'), findsOneWidget);
    expect(find.byType(DynamicUi), findsOneWidget);
  });

  testWidgets('Chat history is maintained', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GenUIHomePage(
        autoStartServer: true,
        aiClient: fakeAiClient,
      ),
    ));
    await tester.pumpAndSettle();

    // First prompt and response
    await tester.enterText(find.byType(TextField), 'First prompt');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('First prompt'), findsOneWidget);
    expect(find.text('Response to "First prompt"'), findsOneWidget);

    // Second prompt and response
    await tester.enterText(find.byType(TextField), 'Second prompt');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Second prompt'), findsOneWidget);
    expect(find.text('Response to "Second prompt"'), findsOneWidget);

    // Check that the first prompt and response are still there.
    expect(find.text('First prompt'), findsOneWidget);
    expect(find.text('Response to "First prompt"'), findsOneWidget);
  });

  testWidgets('Chat scrolls to bottom on new message',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GenUIHomePage(
        autoStartServer: true,
        aiClient: fakeAiClient,
      ),
    ));
    await tester.pumpAndSettle();

    final scrollController =
        tester.widget<ListView>(find.byType(ListView)).controller!;

    // Add enough content to make the list scrollable.
    for (var i = 0; i < 10; i++) {
      await tester.enterText(find.byType(TextField), 'Prompt $i');
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
    }

    // Check that we're scrolled to the bottom.
    expect(scrollController.position.pixels,
        scrollController.position.maxScrollExtent);

    // Add one more message and check that we're still at the bottom.
    await tester.enterText(find.byType(TextField), 'Last prompt');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(scrollController.position.pixels,
        scrollController.position.maxScrollExtent);
  });
}

class FakeAiClient implements AiClient {
  @override
  Future<T?> generateContent<T extends Object>(
    List<Content> prompts,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
    Content? systemInstruction,
  }) async {
    final lastContent = prompts.last;
    if (prompts.any((p) => p.role == 'function')) {
      final response = {
        'actions': [
          {
            'action': 'update',
            'surfaceId': 'surface_0',
            'definition': {
              'root': 'button',
              'widgets': [
                {
                  'id': 'button',
                  'type': 'ElevatedButton',
                  'props': {'child': 'text'},
                },
                {
                  'id': 'text',
                  'type': 'Text',
                  'props': {'data': 'Button clicked!'},
                },
              ],
            }
          }
        ]
      };
      return response as T;
    }
    if (lastContent.role == 'user') {
      final lastPart = lastContent.parts.first as TextPart;
      if (lastPart.text.contains('error')) {
        throw Exception('Something went wrong');
      }
      if (lastPart.text.contains('button')) {
        final response = {
          'actions': [
            {
              'action': 'add',
              'surfaceId': 'surface_0',
              'definition': {
                'root': 'button',
                'widgets': [
                  {
                    'id': 'button',
                    'type': 'ElevatedButton',
                    'props': {'child': 'text'},
                  },
                  {
                    'id': 'text',
                    'type': 'Text',
                    'props': {'data': 'Click Me'},
                  },
                ],
              }
            }
          ]
        };
        return response as T;
      }
      final response = {
        'actions': [
          {
            'action': 'add',
            'surfaceId': 'surface_0',
            'definition': {
              'root': 'root',
              'widgets': [
                {
                  'id': 'root',
                  'type': 'Text',
                  'props': {'data': 'Response to "${lastPart.text}"'},
                },
              ],
            }
          }
        ]
      };
      return response as T;
    }
    final response = {
      'actions': [
        {
          'action': 'add',
          'surfaceId': 'surface_0',
          'definition': {
            'root': 'root',
            'widgets': [
              {
                'id': 'root',
                'type': 'Text',
                'props': {'data': 'A simple response'},
              },
            ],
          }
        }
      ]
    };
    return response as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
