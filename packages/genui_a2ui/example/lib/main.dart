// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
import 'package:logging/logging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureGenUiLogging(level: Level.ALL);
  runApp(const GenUIExampleApp());
}

/// The main application widget.
class GenUIExampleApp extends StatelessWidget {
  /// Creates a [GenUIExampleApp].
  const GenUIExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A2UI Example',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
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
  final A2uiMessageProcessor _a2uiMessageProcessor = A2uiMessageProcessor(
    catalogs: [CoreCatalogItems.asCatalog()],
  );
  late final A2uiContentGenerator _contentGenerator;
  late final GenUiConversation _genUiConversation;
  final List<String> _surfaceIds = ['default'];
  int _currentSurfaceIndex = 0;
  StreamSubscription<GenUiUpdate>? _surfaceSubscription;

  @override
  void initState() {
    super.initState();
    _contentGenerator = A2uiContentGenerator(
      // Replace this with the address of the A2A server (one that supports the
      // A2UI extension) that you wish to connect to.
      serverUrl: Uri.parse('http://localhost:10002'),
    );
    _genUiConversation = GenUiConversation(
      contentGenerator: _contentGenerator,
      a2uiMessageProcessor: _a2uiMessageProcessor,
    );
    // Initialize with existing surfaces
    _surfaceIds.addAll(
      _a2uiMessageProcessor.surfaces.keys.where(
        (id) => !_surfaceIds.contains(id),
      ),
    );

    _surfaceSubscription = _a2uiMessageProcessor.surfaceUpdates.listen((
      update,
    ) {
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
    _a2uiMessageProcessor.dispose();
    _contentGenerator.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
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
        appBar: AppBar(title: const Text('A2UI Example')),
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
                host: _a2uiMessageProcessor,
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
