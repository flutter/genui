# genui_firebase_ai

This package provides the integration between `genui` and the Firebase AI Logic SDK. It allows you to use the power of Google's Gemini models to generate dynamic user interfaces in your Flutter applications.

## Features

- **FirebaseAiContentGenerator:** An implementation of `ContentGenerator` that connects to the Firebase AI SDK.
- **GeminiContentConverter:** Converts between the generic `ChatMessage` and the `firebase_ai` specific `Content` classes.
- **GeminiSchemaAdapter:** Adapts schemas from `json_schema_builder` to the `firebase_ai` format.
- **GeminiGenerativeModelInterface:** An interface for the generative model to allow for mock implementations, primarily for testing.
- **Additional Tools:** Supports adding custom `AiTool`s to extend the AI's capabilities via the `additionalTools` parameter.
- **Error Handling:** Exposes an `errorStream` to listen for and handle any errors during content generation.

## Getting Started

To use this package, you will need to have a Firebase project set up and the Firebase AI SDK configured.

Then, you can create an instance of `FirebaseAiContentGenerator` and pass it to your `GenUiConversation`:

```dart
final catalog = CoreCatalogItems.asCatalog();
final genUiManager = GenUiManager(catalog: catalog);
// Example of a custom tool
final myCustomTool = DynamicAiTool<Map<String, Object?>>(
  name: 'my_custom_action',
  description: 'Performs a custom action.',
  parameters: dsb.S.object(properties: {
    'detail': dsb.S.string(),
  }),
  invokeFunction: (args) async {
    print('Custom action called with: $args');
    return {'status': 'ok'};
  },
);

final contentGenerator = FirebaseAiContentGenerator(
  // model: 'gemini-1.5-pro', // Optional: defaults to gemini-1.5-flash
  catalog: catalog,
  systemInstruction: 'You are a helpful assistant.',
  additionalTools: [myCustomTool],
);
final genUiConversation = GenUiConversation(
  genUiManager: genUiManager,
  contentGenerator: contentGenerator,
  ...
);
```

## Notes

- **Image Handling:** Currently, `ImagePart`s provided with only a `url` (without `bytes` or `base64` data) will be sent to the model as a text description of the URL, as the image data is not automatically fetched by the converter.
- **Token Usage:** The `FirebaseAiContentGenerator` tracks token usage in the `inputTokenUsage` and `outputTokenUsage` properties.
