# flutter_genui_google_generative_ai

This package provides the integration between `flutter_genui` and the Google Cloud Generative Language API. It allows you to use the power of Google's Gemini models to generate dynamic user interfaces in your Flutter applications.

## Features

- **GoogleGenerativeAiContentGenerator:** An implementation of `ContentGenerator` that connects to the Google Cloud Generative Language API.
- **GoogleContentConverter:** Converts between the generic `ChatMessage` and the `google_cloud_ai_generativelanguage_v1beta` specific `Content` classes.
- **GoogleSchemaAdapter:** Adapts schemas from `json_schema_builder` to the Google Cloud API format.

## Getting Started

To use this package, you will need a Gemini API key. If you don't already have one, you can get it for free in [Google AI Studio](https://aistudio.google.com/apikey).

### Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_genui_google_generative_ai:
    path: packages/flutter_genui_google_generative_ai
```

### Usage

Create an instance of `GoogleGenerativeAiContentGenerator` and pass it to your `GenUiConversation`:

```dart
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui_google_generative_ai/flutter_genui_google_generative_ai.dart';

final catalog = Catalog(components: [...]);

final contentGenerator = GoogleGenerativeAiContentGenerator(
  catalog: catalog,
  systemInstruction: 'You are a helpful assistant.',
  modelName: 'models/gemini-2.5-flash',
  apiKey: 'YOUR_API_KEY', // Or set GEMINI_API_KEY environment variable
);

final conversation = GenUiConversation(
  contentGenerator: contentGenerator,
);
```

### API Key Configuration

The API key can be provided in two ways:

1. **Environment Variable** (recommended): Set the `GEMINI_API_KEY` or `GOOGLE_API_KEY` environment variable
2. **Constructor Parameter**: Pass the API key directly to the constructor

If neither is provided, the package will attempt to use the default environment variable.

## Differences from Firebase AI

This package uses the Google Cloud Generative Language API instead of Firebase AI Logic. Key differences:

- **Server-side**: This API is meant for Dart command-line, cloud, and server applications
- **Flutter apps should use Firebase AI**: For mobile and web applications, consider using `flutter_genui_firebase_ai` instead, which provides client-side access

## Example

```dart
// Send a message
await conversation.sendMessage(
  UserMessage(parts: [TextPart('Create a login form')]),
);

// Listen to text responses
conversation.textResponseStream.listen((text) {
  print('AI: $text');
});

// Listen to A2UI messages
conversation.a2uiMessageStream.listen((message) {
  // Handle UI updates
});
```

## Documentation

For more information on the Google Cloud Generative Language API, see:
- [API Documentation](https://pub.dev/documentation/google_cloud_ai_generativelanguage_v1beta/latest/)
- [Gemini API Guide](https://ai.google.dev/gemini-api/docs)

## License

This package is licensed under the BSD-3-Clause license. See [LICENSE](LICENSE) for details.

