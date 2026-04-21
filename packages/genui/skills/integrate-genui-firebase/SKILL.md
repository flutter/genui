---
name: integrate-genui-firebase
description: Use this skill when the user asks to integrate the genui package and get a simple conversation going with Firebase AI Logic.
---

# Integrate GenUI with Firebase AI Logic

## Goal
To successfully integrate the `genui` package into a Flutter app and set up a basic conversational agent using Firebase AI Logic. This skill assumes Firebase AI Logic is already set up and working in the project.

## Instructions
When tasked with integrating `genui` and starting a simple conversation, follow these steps:

1. **Verify Firebase Setup:**
   Ensure `firebase_core` and `firebase_ai` are available in `pubspec.yaml`.
   Verify that `Firebase.initializeApp` is called in the `main()` function:
   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```

2. **Add GenUI Package:**
   Add `genui` to the `pubspec.yaml` dependencies.

3. **Import Required Libraries:**
   Import `genui` and hide `TextPart` so it doesn't conflict with other packages, then import it again with an alias:
   ```dart
   import 'package:genui/genui.dart' hide TextPart;
   import 'package:genui/genui.dart' as genui;
   ```

4. **Configure Basic Logging:**
   At the beginning of the `main()` function, configure GenUI logging:
   ```dart
   configureLogging(
     logCallback: (level, msg) => debugPrint('GenUI $level: $msg'),
   );
   ```

5. **Create Model and Chat Session:**
   Initialize the generative model and start a chat session.
   ```dart
   final model = FirebaseAI.googleAI().generativeModel(
     model: 'gemini-3-flash-preview',
   );
   final _chatSession = model.startChat();
   ```

6. **Identify Target StatefulWidget:**
   **STOP AND ASK THE USER IF UNCLEAR:** This integration requires a `StatefulWidget` to hold the references to GenUI controllers (`SurfaceController`, `A2uiTransportAdapter`, and `Conversation`). Identify which `StatefulWidget` to use in the application. If you are unsure which widget should hold this state, ask the user before proceeding.

7. **Wire up GenUI Controllers inside State:**
   Inside your identified `State` class, instantiate `SurfaceController`, `A2uiTransportAdapter`, and `Conversation`:
   ```dart
   final catalog = BasicCatalogItems.asCatalog(); // Optionally inject custom CatalogItems
   final _controller = SurfaceController(catalogs: [catalog]);
   final _transport = A2uiTransportAdapter(onSend: _sendAndReceive);
   final _conversation = Conversation(
     controller: _controller,
     transport: _transport,
   );
   ```

8. **Implement the `_sendAndReceive` Method:**
   Create a method to take messages from the transport adapter, send them to Firebase, and feed the AI's response back to the transport.
   ```dart
   Future<void> _sendAndReceive(ChatMessage msg) async {
     final buffer = StringBuffer();

     for (final part in msg.parts) {
       if (part.isUiInteractionPart) {
         buffer.write(part.asUiInteractionPart!.interaction);
       } else if (part is genui.TextPart) {
         buffer.write(part.text);
       }
     }

     if (buffer.isEmpty) return;

     final text = buffer.toString();
     final response = await _chatSession.sendMessage(Content.text(text));

     if (response.text?.isNotEmpty ?? false) {
       _transport.addChunk(response.text!);
     }
   }
   ```

9. **Listen to Conversation Events:**
   Create stubbed-out methods in your State class for each event type, including DartDoc comments explaining their required behavior. Depending on the interface design, new surfaces and text coming from the agent will be handled in different ways. A conversational interface might add everything to a list that's display in a `ListView`, for example, while an interface featuring UI components in specific locations (such as headers, footers, etc.) might rely on specific surface IDs given to the agent in the system instruction to know which surfaces to display in which locations.
   ```dart
   /// Updates state to include the new [surfaceId] so a new `Surface` widget can be built.
   void _onSurfaceAdded(String surfaceId) {
     // TODO: Implement state update to add surfaceId
   }

   /// Updates state to remove the [surfaceId] so its `Surface` widget is no longer built.
   void _onSurfaceRemoved(String surfaceId) {
     // TODO: Implement state update to remove surfaceId
   }

   /// Handles displaying raw text content received from the AI to the user.
   void _onContentReceived(String text) {
     // TODO: Implement displaying the received text
   }

   /// Handles errors that occur during the conversation appropriately.
   void _onError(Object error) {
     // TODO: Implement error handling
   }
   ```

   Subscribe to `_conversation.events` to track when UI surfaces or chat messages arrive, dispatching them to the appropriate stubbed out methods:
   ```dart
   _conversation.events.listen((event) {
     switch (event) {
       case ConversationSurfaceAdded added:
         _onSurfaceAdded(added.surfaceId);
       case ConversationSurfaceRemoved removed:
         _onSurfaceRemoved(removed.surfaceId);
       case ConversationContentReceived content:
         _onContentReceived(content.text);
       case ConversationError error:
         _onError(error.error);
       default:
     }
   });
   ```

10. **Initialize System Prompt:**
    Use `PromptBuilder` to give the AI basic instructions, then send it as a system message.
    ```dart
    final promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      instructions: 'You are a helpful assistant. Respond to messages in a chatty way.',
    );
    _conversation.sendRequest(ChatMessage.system(promptBuilder.systemPrompt));
    ```

11. **Display Surfaces:**
    In your Flutter `build()` method, use the `Surface` widget wherever you need to render GenUI widgets using the `surfaceIds` you collected in step 9.
    ```dart
    Surface(surfaceContext: _controller.contextFor(surfaceId));
    ```

12. **Ask User for Input Preferences:**
    **STOP AND ASK THE USER:** Ask the user for clarification on what UI elements should be used for user input. Explain that a `TextField` and `ElevatedButton` are good defaults, but you should not assume they want those exact widgets unless they clarify.

## Constraints
- Do not make assumptions about user input UI elements; see step 12.
- Make sure to properly clean up GenUI controllers (`_transport.dispose()`, `_controller.dispose()`) inside the widget's `dispose()` method.
