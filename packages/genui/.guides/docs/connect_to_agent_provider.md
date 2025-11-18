---
title: Connecting to an agent provider
description: |
  Instructions for connecting `genui` to the agent provider of your
  choice. See `setup.md` for a description of the different `ContentGenerator`
  implementations that are available.
---

Follow these steps to connect `genui` to an agent provider and give
your app the ability to send messages and receive/display generated UI.

The instructions below use a placeholder `YourContentGenerator`. You should
substitute this with your actual `ContentGenerator` implementation (e.g.,
`FirebaseAiContentGenerator` from the `genui_firebase_ai` package).

## 1. Create the `GenUiConversation`

To connect your app, you'll need to instantiate a `GenUiConversation`.
This class orchestrates the interaction between your UI, the `GenUiManager`,
and a `ContentGenerator`.

1.  Create a `GenUiManager`, and provide it with the catalog of widgets you want
    to make available to the agent.
2.  Create a `ContentGenerator` implementation. This is your bridge to the AI
    model. You might need to provide system instructions or other
    configurations here.
3.  Create a `GenUiConversation`, passing in the `GenUiManager` and
    `ContentGenerator` instances. You can also provide callbacks for UI
    events like `onSurfaceAdded`, `onSurfaceUpdated`, `onSurfaceDeleted`, `onTextResponse`, etc.

    For example:

    ```dart
    import 'package:flutter/material.dart';
    import 'package:genui/genui.dart';
    import 'package:genui_firebase_ai/genui_firebase_ai.dart';

    class _MyHomePageState extends State<MyHomePage> {
      late final GenUiManager _genUiManager;
      late final GenUiConversation _genUiConversation;
      final _messages = <ChatMessage>[];

      @override
      void initState() {
        super.initState();

        _genUiManager = GenUiManager(catalog: CoreCatalogItems.asCatalog());

        // Use a concrete implementation of ContentGenerator.
        final contentGenerator = FirebaseAiContentGenerator(
          catalog: _genUiManager.catalog,
          systemInstruction: 'You are a helpful assistant.',
          additionalTools: const [],
        );

        _genUiConversation = GenUiConversation(
          genUiManager: _genUiManager,
          contentGenerator: contentGenerator,
          onSurfaceAdded: _onSurfaceAdded,
          onSurfaceUpdated: _onSurfaceUpdated,
          onSurfaceDeleted: _onSurfaceDeleted,
          onTextResponse: (text) => print('AI Text: $text'),
          onError: (error) => print('AI Error: ${error.error}'),
        );
      }

      void _onSurfaceAdded(SurfaceAdded update) {
        setState(() {
          _messages.add(
            AiUiMessage(
              definition: update.definition,
              surfaceId: update.surfaceId,
            ),
          );
        });
      }

      void _onSurfaceUpdated(SurfaceUpdated update) {
        // Handle surface updates if needed. For example, you might want to
        // scroll to the bottom of a list when a surface is updated.
        print('Surface ${update.surfaceId} updated');
      }

      void _onSurfaceDeleted(SurfaceRemoved update) {
        setState(
          () => _messages.removeWhere(
            (m) => m is AiUiMessage && m.surfaceId == update.surfaceId,
          ),
        );
      }

      @override
      void dispose() {
        _genUiConversation.dispose();
        // _genUiManager is disposed by _genUiConversation
        super.dispose();
      }
    }
    ```

### 2. Send messages and display the agent's responses

Send a message to the agent using the `sendRequest` method in the `GenUiConversation`
class.

To receive and display generated UI:

1. Use `GenUiConversation`'s callbacks (e.g., `onSurfaceAdded`, `onSurfaceDeleted`)
   to track the addition and removal of UI surfaces.
2. Build a `GenUiSurface` widget for each active surface ID.
   Make sure to provide the host: `_genUiConversation.host`.

    For example:

    ```dart
    class _MyHomePageState extends State<MyHomePage> {

      // ...

      final _textController = TextEditingController();
      final _messages = <ChatMessage>[];

      // Send a message containing the user's text to the agent.
      void _sendMessage(String text) {
        if (text.trim().isEmpty) return;
        final message = UserMessage.text(text);
        setState(() => _messages.add(message));
        _genUiConversation.sendRequest(message);
      }

      void _onSurfaceAdded(SurfaceAdded update) {
        setState(() {
          _messages.add(
            AiUiMessage(
              definition: update.definition,
              surfaceId: update.surfaceId,
            ),
          );
        });
      }

      // ... other callbacks

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return switch (message) {
                      AiUiMessage() => GenUiSurface(
                          host: _genUiConversation.host,
                          surfaceId: message.surfaceId,
                        ),
                      AiTextMessage() => ListTile(title: Text(message.text)),
                      UserMessage() => ListTile(title: Text(message.text)),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ),
              // ... text input row
            ],
          ),
        );
      }
    }
    ```
