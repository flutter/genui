import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/main.dart';
import 'package:genui_client/src/ai_client/ai_client.dart';
import 'package:genui_client/src/ai_server/ai_server.dart';
import 'package:genui_client/src/dynamic_ui.dart';
import 'package:genui_client/src/tools/tools.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:platform/platform.dart';

class MockAiClient extends AiClient {
  MockAiClient({
    super.model = 'gemini-2.5-flash',
    Platform? platform,
    super.apiKey = 'FAKE_API_KEY',
  }) : super(platform: platform ?? FakePlatform());

  int _callCount = 0;
  final receivedPrompts = <List<Content>>[];

  final _responses = [
    {
      'task_id': 'task-123',
      'root': 'button',
      'widgets': {
        'button': {
          'id': 'button',
          'type': 'ElevatedButton',
          'props': {'child': 'text'},
        },
        'text': {
          'id': 'text',
          'type': 'Text',
          'props': {'data': 'Click Me'},
        },
      },
    },
    {
      'task_id': 'task-123',
      'root': 'root',
      'widgets': {
        'root': {
          'id': 'root',
          'type': 'Text',
          'props': {'data': 'Button clicked!'},
        },
      },
    },
  ];

  @override
  Future<T?> generateContent<T extends Object>(
    List<Content> prompts,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
    Content? systemInstruction,
  }) async {
    receivedPrompts.add(prompts);
    if (_callCount >= _responses.length) {
      return {
        'root': 'root',
        'widgets': {
          'root': {
            'id': 'root',
            'type': 'Text',
            'props': {'data': 'Out of responses'},
          },
        },
      } as T;
    }
    return _responses[_callCount++] as T;
  }
}

class MockErrorAiClient extends AiClient {
  MockErrorAiClient({
    super.model = 'gemini-2.5-flash',
    Platform? platform,
    super.apiKey = 'FAKE_API_KEY',
  }) : super(platform: platform ?? FakePlatform());

  @override
  Future<T?> generateContent<T extends Object>(
    List<Content> prompts,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
    Content? systemInstruction,
  }) async {
    throw Exception('Something went wrong');
  }
}

void main() {
  testWidgets('MyHomePage shows server started status after startup',
      (WidgetTester tester) async {
    final homePageKey = GlobalKey<State<MyHomePage>>();
    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(key: homePageKey, autoStartServer: false),
    ));
    expect(find.text('Initializing...'), findsOneWidget);

    // Replace the default server spawner with one that uses a mock AiClient.
    (homePageKey.currentState as dynamic).serverSpawnerOverride =
        (SendPort sendPort) async {
      return await Isolate.spawn(
        serverIsolateTest,
        [sendPort, MockAiClient()],
      );
    };

    await tester.runAsync(() async {
      await (homePageKey.currentState as dynamic).startServer();
    });
    await tester.pumpAndSettle();
    expect(find.text('Server started.'), findsOneWidget);

    // Dispose the widget to clean up resources.
    await tester.pumpWidget(Container());
  }, timeout: const Timeout(Duration(seconds: 10)));

  testWidgets('DynamicUi is created and handles events',
      (WidgetTester tester) async {
    final homePageKey = GlobalKey<State<MyHomePage>>();
    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(key: homePageKey, autoStartServer: false),
    ));

    final mockAiClient = MockAiClient();

    // Replace the default server spawner with one that uses a mock AiClient.
    (homePageKey.currentState as dynamic).serverSpawnerOverride =
        (SendPort sendPort) async {
      return await Isolate.spawn(
        serverIsolateTest,
        [sendPort, mockAiClient],
      );
    };

    await tester.runAsync(() async {
      await (homePageKey.currentState as dynamic).startServer();
    });

    await tester.pumpAndSettle();

    // Enter a prompt and send it.
    await tester.enterText(find.byType(TextField), 'A simple button');
    await tester.tap(find.byType(IconButton));
    await tester.pump();

    // The server is running in an isolate, so we need to wait for the response.
    // We expect a CircularProgressIndicator to be showing while waiting.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the server to respond and the UI to be built.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    // After the server responds, the DynamicUi widget should be present.
    expect(find.byType(DynamicUi), findsOneWidget);
    expect(find.text('Click Me'), findsOneWidget);

    // Tap the button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    // Check that the UI updated
    expect(find.text('Button clicked!'), findsOneWidget);

    // Verify that the AI client was called. The UI check is sufficient.
  }, timeout: const Timeout(Duration(seconds: 20)));

  testWidgets('UI shows error when AI client throws an exception',
      (WidgetTester tester) async {
    final homePageKey = GlobalKey<State<MyHomePage>>();
    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(key: homePageKey, autoStartServer: false),
    ));

    // Replace the default server spawner with one that uses a mock AiClient.
    (homePageKey.currentState as dynamic).serverSpawnerOverride =
        (SendPort sendPort) async {
      return await Isolate.spawn(
        serverIsolateTest,
        [sendPort, MockErrorAiClient()],
      );
    };

    await tester.runAsync(() async {
      await (homePageKey.currentState as dynamic).startServer();
    });

    await tester.pumpAndSettle();

    // Enter a prompt and send it.
    await tester.enterText(find.byType(TextField), 'A simple button');
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    // Check that the UI shows an error message.
    expect(find.text('Error: Exception: Something went wrong'), findsOneWidget);
  });
}
