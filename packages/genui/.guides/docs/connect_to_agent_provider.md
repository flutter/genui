---
title: Connecting to an agent provider
description: |
  Instructions for connecting `genui` to the agent provider of your
  choice.
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

    // Replace with your actual ContentGenerator implementation
    class YourContentGenerator implements ContentGenerator {
      // ... implementation details ...
      @override
      Stream<A2uiMessage> get a2uiMessageStream => Stream.empty(); // Replace
      @override
      Stream<String> get textResponseStream => Stream.empty(); // Replace
      @override
      Stream<ContentGeneratorError> get errorStream => Stream.empty(); // Replace
      @override
      ValueListenable<bool> get isProcessing => ValueNotifier(false); // Replace
      @override
      Future<void> sendRequest(
        ChatMessage message, {
        Iterable<ChatMessage>? history,
      }) async { /* ... */ }
      @override
      void dispose() { /* ... */ }
    }

    class _MyHomePageState extends State<MyHomePage> {
      late final GenUiManager _genUiManager;
      late final GenUiConversation _genUiConversation;
      final _surfaceIds = <String>[];

      @override
      void initState() {
        super.initState();

        _genUiManager = GenUiManager(catalog: CoreCatalogItems.asCatalog());

        // NOTE: You need a concrete implementation of ContentGenerator here.
        // The 'genui_firebase_ai' package provides implementations
        // like FirebaseAiContentGenerator.
        final contentGenerator = YourContentGenerator();

        _genUiConversation = GenUiConversation(
          genUiManager: _genUiManager,
          contentGenerator: contentGenerator,
          onSurfaceAdded: _onSurfaceAdded,
          onSurfaceUpdated: _onSurfaceUpdated, // Example callback
          onSurfaceDeleted: _onSurfaceDeleted,
          onTextResponse: (text) => print('AI Text: $text'),
          onError: (error) => print('AI Error: ${error.error}'),
        );
      }

      void _onSurfaceAdded(SurfaceAdded update) {
        setState(() => _surfaceIds.add(update.surfaceId));
      }

      void _onSurfaceUpdated(SurfaceUpdated update) {
        // Handle surface updates if needed
        print('Surface ${update.surfaceId} updated');
      }

      void _onSurfaceDeleted(SurfaceRemoved update) {
        setState(() => _surfaceIds.remove(update.surfaceId));
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
      final _surfaceIds = <String>[];

      // Send a message containing the user's text to the agent.
      void _sendMessage(String text) {
        if (text.trim().isEmpty) return;
        _genUiConversation.sendRequest(UserMessage.text(text));
      }

      // Callbacks for GenUiConversation (defined in initState example above)
      // void _onSurfaceAdded(SurfaceAdded update) { ... }
      // void _onSurfaceUpdated(SurfaceUpdated update) { ... }
      // void _onSurfaceDeleted(SurfaceRemoved update) { ... }

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
                 itemCount: _surfaceIds.length,
                 itemBuilder: (context, index) {
                   // For each surface, create a GenUiSurface to display it.
                   final id = _surfaceIds[index];
                   final controller = _genUiConversation.getSurfaceController(id);
                   return GenUiSurface(controller: controller);
                 },
               ),
             ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Enter a message',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Send the user's text to the agent.
                          _sendMessage(_textController.text);
                          _textController.clear();
                        },
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    ```
