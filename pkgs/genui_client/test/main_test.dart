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
    expect(find.text('Server started.'), findsOneWidget);
  });

  testWidgets('DynamicUi is created and handles events',
      (WidgetTester tester) async {
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

    expect(find.text('Button clicked!'), findsOneWidget);
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
    await tester.pumpAndSettle();

    expect(find.text('Error: Exception: Something went wrong'), findsOneWidget);
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
    if (lastContent.role == 'user') {
      final lastPart = lastContent.parts.first as TextPart;
      if (lastPart.text.contains('error')) {
        throw Exception('Something went wrong');
      }
      if (lastPart.text.contains('button')) {
        return <String, Object?>{
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
        } as T;
      }
    } else if (lastContent.role == 'function') {
      return <String, Object?>{
        'root': 'root',
        'widgets': [
          {
            'id': 'root',
            'type': 'Text',
            'props': {'data': 'Button clicked!'},
          },
        ],
      } as T;
    }
    return <String, Object?>{
      'root': 'root',
      'widgets': [
        {
          'id': 'root',
          'type': 'Text',
          'props': {'data': 'Button clicked!'},
        },
      ],
    } as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
