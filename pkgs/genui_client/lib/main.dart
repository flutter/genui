import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/ai_client/ai_client.dart';
import 'src/dynamic_ui.dart';
import 'src/ui_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('debug'),
  );
  runApp(const GenUIApp());
}

/// The main application widget for the GenUI demo application.
///
/// This widget sets up the root of the application, configuring the
/// [MaterialApp] with a title, theme, and the main home page. It serves as the
/// entry point for the Flutter UI.
class GenUIApp extends StatelessWidget {
  /// Creates the main application widget.
  const GenUIApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic UI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GenUIHomePage(),
    );
  }
}

/// The primary screen of the application, responsible for managing the user
/// interface and interaction with the AI backend.
///
/// This stateful widget handles:
/// - Establishing and managing the connection to the UI server.
/// - Providing a text input field for the user to enter prompts.
/// - Displaying the dynamically generated UI received from the server via the
///   [DynamicUi] widget.
/// - Forwarding UI events from the [DynamicUi] widget back to the server.
/// - Showing connection status and error messages to the user.
class GenUIHomePage extends StatefulWidget {
  /// Creates an instance of the GenUI home page.
  ///
  /// The [autoStartServer], [connectionFactory], and [aiClient] parameters are
  /// primarily for testing purposes, allowing for dependency injection and
  /// controlled startup.
  const GenUIHomePage({
    super.key,
    this.autoStartServer = true,
    this.connectionFactory = createStreamServerConnection,
    this.aiClient,
  });

  /// When true, the UI server connection is automatically initiated when the
  /// widget is initialized.
  final bool autoStartServer;

  /// A factory function used to create the [ServerConnection] instance.
  /// This allows for replacing the default stream-based connection with a mock
  /// or alternative implementation for testing.
  final ServerConnectionFactory connectionFactory;

  /// The [AiClient] instance to be used by the server for generating UI.
  /// If not provided, a default client will be instantiated. This is useful for
  /// injecting a mock AI client during tests.
  final AiClient? aiClient;

  @override
  State<GenUIHomePage> createState() => _GenUIHomePageState();
}

class _GenUIHomePageState extends State<GenUIHomePage> {
  final _updateController = StreamController<Map<String, Object?>>.broadcast();
  Map<String, Object?>? _uiDefinition;
  String _connectionStatus = 'Initializing...';
  Key _uiKey = UniqueKey();
  final _promptController = TextEditingController();
  late final ServerConnection _serverConnection;

  @override
  void initState() {
    super.initState();
    _serverConnection = widget.connectionFactory(
      onSetUi: (definition) {
        if (!mounted) return;
        setState(() {
          _uiDefinition = definition;
          _uiKey = UniqueKey();
        });
      },
      onUpdateUi: (updates) {
        if (!mounted) return;
        for (final update in updates) {
          _updateController.add(update);
        }
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _connectionStatus = 'Error: $message';
          _uiDefinition = null;
        });
      },
      onStatusUpdate: (status) {
        if (!mounted) return;
        setState(() {
          _connectionStatus = status;
          if (status != 'Server started.') {
            _uiDefinition = null;
          }
        });
      },
      aiClient: widget.aiClient,
    );

    if (widget.autoStartServer) {
      _serverConnection.start();
    }
  }

  @override
  void dispose() {
    _updateController.close();
    _serverConnection.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _handleUiEvent(Map<String, Object?> event) {
    _serverConnection.sendUiEvent(event);
  }

  void _sendPrompt() {
    final prompt = _promptController.text;
    _serverConnection.sendPrompt(prompt);
    if (prompt.isNotEmpty) {
      _promptController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Dynamic UI Demo'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          hintText: 'Enter a UI prompt',
                        ),
                        onSubmitted: (_) => _sendPrompt(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendPrompt,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _uiDefinition == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_connectionStatus == 'Generating UI...')
                              const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(_connectionStatus),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DynamicUi(
                          key: _uiKey,
                          definition: _uiDefinition!,
                          updateStream: _updateController.stream,
                          onEvent: _handleUiEvent,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
