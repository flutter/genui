// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_dartantic/genui_dartantic.dart';
import 'package:logging/logging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureGenUiLogging(level: Level.ALL);
  runApp(const DartanticExampleApp());
}

/// The main application widget.
class DartanticExampleApp extends StatelessWidget {
  /// Creates a [DartanticExampleApp].
  const DartanticExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dartantic GenUI Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatScreen(),
    );
  }
}

/// The main chat screen.
class ChatScreen extends StatefulWidget {
  /// Creates a [ChatScreen].
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final GenUiManager _genUiManager = GenUiManager(
    catalog: CoreCatalogItems.asCatalog(),
  );
  late final DartanticContentGenerator _contentGenerator;
  late final GenUiConversation _genUiConversation;
  final List<String> _surfaceIds = ['default'];
  int _currentSurfaceIndex = 0;
  StreamSubscription<GenUiUpdate>? _surfaceSubscription;

  // API key passed via --dart-define=GOOGLE_API_KEY=...
  static const String _googleApiKeyEnv = String.fromEnvironment(
    'GOOGLE_API_KEY',
  );
  static String? get _googleApiKey =>
      _googleApiKeyEnv.isEmpty ? null : _googleApiKeyEnv;

  @override
  void initState() {
    super.initState();

    // Use Google provider by default. The API key can be passed via:
    //   1. --dart-define=GOOGLE_API_KEY=your-key (for VS Code launch)
    //   2. GEMINI_API_KEY environment variable (dartantic default)
    // You can also use other providers like:
    //   - dartantic.Providers.openai (requires OPENAI_API_KEY)
    //   - dartantic.Providers.anthropic (requires ANTHROPIC_API_KEY)
    //   - dartantic.Providers.ollama (local, no API key required)
    _contentGenerator = DartanticContentGenerator(
      provider: dartantic.GoogleProvider(apiKey: _googleApiKey),
      catalog: CoreCatalogItems.asCatalog(),
      systemInstruction:
          'You are a helpful assistant that creates UI widgets. '
          'When asked to show something, use the surface_update tool to create '
          'appropriate UI components.',
    );

    _genUiConversation = GenUiConversation(
      contentGenerator: _contentGenerator,
      genUiManager: _genUiManager,
    );

    // Initialize with existing surfaces
    _surfaceIds.addAll(
      _genUiManager.surfaces.keys.where((id) => !_surfaceIds.contains(id)),
    );

    _surfaceSubscription = _genUiManager.surfaceUpdates.listen((update) {
      if (update is SurfaceAdded) {
        genUiLogger.info('Surface added: ${update.surfaceId}');
        if (!_surfaceIds.contains(update.surfaceId)) {
          setState(() {
            _surfaceIds.add(update.surfaceId);
            // Switch to the new surface
            _currentSurfaceIndex = _surfaceIds.length - 1;
          });
        }
      } else if (update is SurfaceUpdated) {
        genUiLogger.info('Surface updated: ${update.surfaceId}');
        // The surface will redraw itself, but we call setState here to ensure
        // that any other dependent widgets are also updated.
        setState(() {});
      } else if (update is SurfaceRemoved) {
        genUiLogger.info('Surface removed: ${update.surfaceId}');
        if (_surfaceIds.contains(update.surfaceId)) {
          setState(() {
            final int removeIndex = _surfaceIds.indexOf(update.surfaceId);
            _surfaceIds.removeAt(removeIndex);
            if (_surfaceIds.isEmpty) {
              _currentSurfaceIndex = 0;
            } else {
              if (_currentSurfaceIndex >= removeIndex &&
                  _currentSurfaceIndex > 0) {
                _currentSurfaceIndex--;
              }
              if (_currentSurfaceIndex >= _surfaceIds.length) {
                _currentSurfaceIndex = _surfaceIds.length - 1;
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _genUiConversation.dispose();
    _surfaceSubscription?.cancel();
    _genUiManager.dispose();
    _contentGenerator.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _genUiConversation.sendRequest(UserMessage.text(text));
  }

  void _previousSurface() {
    if (_currentSurfaceIndex > 0) {
      setState(() {
        _currentSurfaceIndex--;
      });
    }
  }

  void _nextSurface() {
    if (_currentSurfaceIndex < _surfaceIds.length - 1) {
      setState(() {
        _currentSurfaceIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_surfaceIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dartantic GenUI Example')),
        body: const Center(child: Text('No surfaces available.')),
      );
    }
    final String currentSurfaceId = _surfaceIds[_currentSurfaceIndex];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousSurface,
          tooltip: 'Previous Surface',
          color: _currentSurfaceIndex > 0
              ? null
              : Theme.of(context).disabledColor,
        ),
        title: Text('Surface: $currentSurfaceId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _nextSurface,
            tooltip: 'Next Surface',
            color: _currentSurfaceIndex < _surfaceIds.length - 1
                ? null
                : Theme.of(context).disabledColor,
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ValueListenableBuilder<List<ChatMessage>>(
                    valueListenable: _genUiConversation.conversation,
                    builder: (context, messages, child) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        reverse: true,
                        itemBuilder: (_, int index) =>
                            _buildMessage(messages.reversed.toList()[index]),
                        itemCount: messages.length,
                      );
                    },
                  ),
                ),
                const Divider(height: 1.0),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: _buildTextComposer(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: GenUiSurface(
                key: ValueKey(currentSurfaceId),
                host: _genUiManager,
                surfaceId: currentSurfaceId,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUserMessage = message is UserMessage;
    var text = '';
    if (message is UserMessage) {
      text = message.text;
    } else if (message is AiTextMessage) {
      text = message.text;
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: Text(isUserMessage ? 'U' : 'A')),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isUserMessage ? 'User' : 'Agent',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Send a message',
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
