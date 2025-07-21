import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/main.dart';
import 'package:genui_client/src/dynamic_ui.dart';

class MockFirebaseApp implements FirebaseApp {
  @override
  String get name => 'test';

  @override
  FirebaseOptions get options => const FirebaseOptions(
        apiKey: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        projectId: 'test',
      );

  @override
  Future<void> delete() async {}

  @override
  bool get isAutomaticDataCollectionEnabled => false;

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}
}

class MockServerConnection implements ServerConnection {
  MockServerConnection({
    required this.firebaseApp,
    required this.onSetUi,
    required this.onUpdateUi,
    required this.onError,
    required this.onStatusUpdate,
    this.serverSpawnerOverride,
  });

  // ignore: unreachable_from_main
  final FirebaseApp firebaseApp;
  final SetUiCallback onSetUi;
  // ignore: unreachable_from_main
  final UpdateUiCallback onUpdateUi;
  final ErrorCallback onError;
  final StatusUpdateCallback onStatusUpdate;
  // ignore: unreachable_from_main
  final ServerSpawner? serverSpawnerOverride;

  String? lastPrompt;
  Map<String, Object?>? lastEvent;

  @override
  Future<void> start() async {
    onStatusUpdate('Server started.');
  }

  @override
  void sendPrompt(String text) {
    lastPrompt = text;
    onStatusUpdate('Generating UI...');
  }

  @override
  void sendUiEvent(Map<String, Object?> event) {
    lastEvent = event;
    onStatusUpdate('Generating UI...');
  }

  @override
  void dispose() {}
}

void main() {
  late FirebaseApp mockFirebaseApp;
  late MockServerConnection mockConnection;

  ServerConnection connectionFactory({
    required FirebaseApp firebaseApp,
    required SetUiCallback onSetUi,
    required UpdateUiCallback onUpdateUi,
    required ErrorCallback onError,
    required StatusUpdateCallback onStatusUpdate,
    ServerSpawner? serverSpawnerOverride,
  }) {
    mockConnection = MockServerConnection(
      firebaseApp: firebaseApp,
      onSetUi: onSetUi,
      onUpdateUi: onUpdateUi,
      onError: onError,
      onStatusUpdate: onStatusUpdate,
      serverSpawnerOverride: serverSpawnerOverride,
    );
    return mockConnection;
  }

  setUp(() {
    mockFirebaseApp = MockFirebaseApp();
  });

  testWidgets('GenUIHomePage shows server started status after startup',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GenUIHomePage(
        autoStartServer: true,
        firebaseApp: mockFirebaseApp,
        connectionFactory: connectionFactory,
      ),
    ));
    await tester.pump();
    expect(find.text('Server started.'), findsOneWidget);
  });

  testWidgets('DynamicUi is created and handles events',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GenUIHomePage(
        autoStartServer: true,
        firebaseApp: mockFirebaseApp,
        connectionFactory: connectionFactory,
      ),
    ));
    await tester.pump();

    // Enter a prompt and send it.
    await tester.enterText(find.byType(TextField), 'A simple button');
    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(mockConnection.lastPrompt, 'A simple button');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Simulate server response
    mockConnection.onSetUi({
      'task_id': 'task-123',
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
    });
    await tester.pump();

    expect(find.byType(DynamicUi), findsOneWidget);
    expect(find.text('Click Me'), findsOneWidget);

    // Tap the button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(mockConnection.lastEvent, isNotNull);
    expect(mockConnection.lastEvent!['widgetId'], 'button');

    // Simulate server response to event
    mockConnection.onSetUi({
      'task_id': 'task-123',
      'root': 'root',
      'widgets': [
        {
          'id': 'root',
          'type': 'Text',
          'props': {'data': 'Button clicked!'},
        },
      ],
    });
    await tester.pump();

    expect(find.text('Button clicked!'), findsOneWidget);
  });

  testWidgets('UI shows error when AI client throws an exception',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GenUIHomePage(
        autoStartServer: true,
        firebaseApp: mockFirebaseApp,
        connectionFactory: connectionFactory,
      ),
    ));
    await tester.pump();

    // Simulate an error from the server
    mockConnection.onError('Something went wrong');
    await tester.pump();

    expect(find.text('Error: Something went wrong'), findsOneWidget);
  });
}
