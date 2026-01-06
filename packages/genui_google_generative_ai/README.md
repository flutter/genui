# genui_google_generative_ai

This package provides the integration between `genui` and the Google Cloud Generative Language API. It allows you to use the power of Google's Gemini models to generate dynamic user interfaces in your Flutter applications.

## Features

- **GoogleGenerativeAiContentGenerator:** An implementation of `ContentGenerator` that connects to the Google Cloud Generative Language API.
- **GoogleContentConverter:** Converts between the generic `ChatMessage` and the `google_cloud_ai_generativelanguage_v1beta` specific `Content` classes.
- **GoogleSchemaAdapter:** Adapts schemas from `json_schema_builder` to the Google Cloud API format.

## Getting Started

To use this package, you will need a Gemini API key. If you don't already have one, you can get it for free in [Google AI Studio](https://aistudio.google.com/apikey).

### Installation

Use `flutter pub add` to add the latest versions of `genui` and `genui_google_generative_ai` as
dependencies in your `pubspec.yaml` file:

```bash
flutter pub add genui genui_google_generative_ai
```

### Usage

Create an instance of `GoogleGenerativeAiContentGenerator` and pass it to your `GenUiConversation`:

```dart
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';

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

1. **Environment Variable** (recommended): Set the `GEMINI_API_KEY` environment variable
2. **Constructor Parameter**: Pass the API key directly to the constructor

If neither is provided, the package will attempt to use the default environment variable.

## Differences from Firebase AI

This package uses the Google Cloud Generative Language API instead of Firebase AI Logic.

This API is meant for quick explorations and local testing or prototyping,
not for production or deployment.

**Flutter apps built for production should use Firebase AI**: For mobile and
web applications, consider using `genui_firebase_ai` instead, which provides client-side access

## Documentation

For more information on the Google Cloud Generative Language API, see:
- [API Documentation](https://pub.dev/documentation/google_cloud_ai_generativelanguage_v1beta/latest/)
- [Gemini API Guide](https://ai.google.dev/gemini-api/docs)

## License

This package is licensed under the BSD-3-Clause license. See [LICENSE](LICENSE) for details.
