# flutter_genui_a2ui

An integration package for `flutter_genui` and the A2UI Streaming UI Protocol. This package allows Flutter applications to connect to an A2A server and render dynamic user interfaces using the `flutter_genui` framework.

## Features

- Connects to an A2A (Agent-to-Agent) server.
- Receives and processes A2UI (Agent-to-UI) protocol messages.
- Renders dynamic user interfaces using `flutter_genui`'s `GenUiSurface`.
- Provides an `A2uiAiClient` implementation for `flutter_genui`'s `UiAgent`.

## Getting Started

### Add to your project

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_genui_a2ui: ^0.1.0
```

Then run `flutter pub get`.

### Usage

To use this package, you need to:

1.  Initialize a `GenUiManager` with your desired `Catalog`.
2.  Create an `A2uiAiClient` instance, providing the A2A server URL and the `GenUiManager`.
3.  Create a `UiAgent` instance with the `A2uiAiClient` and `GenUiManager`.
4.  Use a `GenUiSurface` widget in your Flutter application to render the AI-generated UI.
5.  Send user messages to the `UiAgent` using `sendRequest`.

Here's a basic example:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_a2ui/flutter_genui_a2ui.dart';

void main() {
  runApp(const GenUIExampleApp());
}

class GenUIExampleApp extends StatelessWidget {
  const GenUIExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A2UI Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final GenUiManager _genUiManager =
      GenUiManager(catalog: CoreCatalogItems.asCatalog());
  late final A2uiAiClient _aiClient;
  late final UiAgent _uiAgent;
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _aiClient = A2uiAiClient(
      serverUrl: Uri.parse('http://localhost:8080'), // Replace with your A2A server URL
      genUiManager: _genUiManager,
    );
    _uiAgent = UiAgent(
      aiClient: _aiClient,
      genUiManager: _genUiManager,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _uiAgent.dispose();
    _genUiManager.dispose();
    _aiClient.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.add(UserMessage.text(text));
    });
    _uiAgent.sendRequest(UserMessage.text(text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A2UI Example'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) =>
                  _buildMessage(_messages[index]),
              itemCount: _messages.length,
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
          SizedBox(
              height: 200,
              child: GenUiSurface(
                host: _genUiManager,
                surfaceId: '1',
              )),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: const CircleAvatar(child: Text('U')),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('User',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text((message as UserMessage).text),
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
                decoration:
                    const InputDecoration.collapsed(hintText: 'Send a message'),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_textController.text)),
            ),
          ],
        ),
      ),
    );
  }
}
