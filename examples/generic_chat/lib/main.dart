import 'package:collection/collection.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'firebase_options.dart';
import 'src/chat_message.dart';
import 'src/core_catalog.dart';
import 'src/dynamic_ui.dart';
import 'src/ui_models.dart';
import 'src/ui_server.dart';
import 'src/widget_tree_llm_adapter.dart';

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
  final _chatHistory = <ChatMessage>[];
  String _connectionStatus = 'Initializing...';
  final _promptController = TextEditingController();
  late final ServerConnection _serverConnection;
  final ScrollController _scrollController = ScrollController();
  final widgetTreeLlmAdapter = WidgetTreeLlmAdapter(coreCatalog);

  @override
  void initState() {
    super.initState();
    _serverConnection = widget.connectionFactory(
      onSetUi: (definition) {
        if (!mounted) return;
        setState(() {
          final surfaceId = definition['surfaceId'] as String?;
          _chatHistory.add(UiResponse(
            definition: definition,
            surfaceId: surfaceId,
          ));
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      },
      onUpdateUi: (updates) {
        if (!mounted) return;
        setState(() {
          for (final update in updates) {
            final uiUpdate = UiDefinition.fromMap(update);
            final oldResponse =
                _chatHistory.whereType<UiResponse>().firstWhereOrNull(
                      (response) => response.surfaceId == uiUpdate.surfaceId,
                    );
            if (oldResponse != null) {
              final index = _chatHistory.indexOf(oldResponse);
              _chatHistory[index] =
                  UiResponse(definition: update, surfaceId: uiUpdate.surfaceId);
            }
          }
        });
      },
      onDeleteUi: (surfaceId) {
        if (!mounted) return;
        setState(() {
          _chatHistory.removeWhere((message) =>
              message is UiResponse && message.surfaceId == surfaceId);
        });
      },
      onTextResponse: (text) {
        if (!mounted) return;
        setState(() {
          _chatHistory.add(TextResponse(text: text));
        });
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _chatHistory.add(SystemMessage(text: 'Error: $message'));
          _connectionStatus = 'Error: $message';
        });
      },
      onStatusUpdate: (status) {
        if (!mounted) return;
        setState(() {
          _connectionStatus = status;
          if (status == 'Server started.' && _chatHistory.isEmpty) {
            _chatHistory
                .add(const SystemMessage(text: 'What can I do for you?'));
          }
        });
      },
      aiClient: widget.aiClient,
      widgetTreeLlmAdapter: widgetTreeLlmAdapter,
    );

    if (widget.autoStartServer) {
      _serverConnection.start();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _serverConnection.dispose();
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleUiEvent(Map<String, Object?> event) {
    _serverConnection.sendUiEvent(event);
  }

  void _sendPrompt() {
    final prompt = _promptController.text;
    if (prompt.isNotEmpty) {
      setState(() {
        _chatHistory.add(UserPrompt(text: prompt));
      });
      _serverConnection.sendPrompt(prompt);
      _promptController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProgressIndicator = _connectionStatus == 'Generating UI...' ||
        _connectionStatus == 'Starting server...';
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
              Expanded(
                child: _chatHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (showProgressIndicator)
                              const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(_connectionStatus),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _chatHistory.length,
                        itemBuilder: (context, index) {
                          final message = _chatHistory[index];
                          return switch (message) {
                            SystemMessage() => Card(
                                elevation: 2.0,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: ListTile(
                                  title: Text(message.text),
                                  leading: const Icon(Icons.smart_toy_outlined),
                                ),
                              ),
                            TextResponse() => Card(
                                elevation: 2.0,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: ListTile(
                                  title: Text(message.text),
                                  leading: const Icon(Icons.smart_toy_outlined),
                                ),
                              ),
                            UserPrompt() => Card(
                                elevation: 2.0,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: ListTile(
                                  title: Text(
                                    message.text,
                                    textAlign: TextAlign.right,
                                  ),
                                  trailing: const Icon(Icons.person),
                                ),
                              ),
                            UiResponse() => Card(
                                elevation: 2.0,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: DynamicUi(
                                    key: message.uiKey,
                                    catalog: widgetTreeLlmAdapter.catalog,
                                    surfaceId: message.surfaceId,
                                    definition: UiDefinition.fromMap(
                                        message.definition),
                                    onEvent: _handleUiEvent,
                                  ),
                                ),
                              ),
                          };
                        },
                      ),
              ),
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
              if (showProgressIndicator)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Generating UI...'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
