# flutter_genui_firebase_ai

This package provides the integration between `flutter_genui` and the Firebase AI Logic SDK. It allows you to use the power of Google's Gemini models to generate dynamic user interfaces in your Flutter applications.

## Features

*   **FirebaseAiClient:** An implementation of `AiClient` that connects to the Firebase AI SDK.
*   **GeminiContentConverter:** Converts between the generic `ChatMessage` and the `firebase_ai` specific `Content` classes.
*   **GeminiSchemaAdapter:** Adapts schemas from `dart_schema_builder` to the `firebase_ai` format.

## Getting Started

To use this package, you will need to have a Firebase project set up and the Firebase AI SDK configured.

Then, you can create an instance of `FirebaseAiClient` and pass it to your `UiAgent`:

```dart
final genUiManager = GenUiManager(catalog: catalog);
final aiClient = FirebaseAiClient(
  systemInstruction: 'You are a helpful assistant.',
  tools: genUiManager.getTools(),
);
final uiAgent = UiAgent(
  genUiManager: genUiManager,
  aiClient: aiClient,
  ...
);
```