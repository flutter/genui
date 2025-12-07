# genui_dartantic

This package provides the integration between `genui` and the Dartantic AI package. It allows you to use multiple AI providers (OpenAI, Anthropic, Google, Mistral, Cohere, Ollama) to generate dynamic user interfaces in your Flutter applications.

## Features

- **DartanticContentGenerator:** An implementation of `ContentGenerator` that uses the dartantic_ai package to connect to various AI providers.
- **Multi-Provider Support:** Use any provider supported by dartantic_ai including OpenAI, Anthropic, Google, Mistral, Cohere, and Ollama.
- **DartanticContentConverter:** Converts between GenUI `ChatMessage` types and text formats suitable for dartantic_ai.
- **DartanticSchemaAdapter:** Adapts schemas from `json_schema_builder` to the dartantic_ai `JsonSchema` format.
- **Additional Tools:** Supports adding custom `AiTool`s to extend the AI's capabilities via the `additionalTools` parameter.
- **Error Handling:** Exposes an `errorStream` to listen for and handle any errors during content generation.
- **Stateful Conversations:** Uses dartantic_ai's `Chat` class for automatic conversation history management.

## Getting Started

To use this package, add it to your `pubspec.yaml`:

```yaml
dependencies:
  genui_dartantic: ^0.5.1
  dartantic_ai: ^1.3.0
  genui: ^0.5.1
```

Then, create an instance of `DartanticContentGenerator` and pass it to your `GenUiConversation`:

```dart
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:genui/genui.dart';
import 'package:genui_dartantic/genui_dartantic.dart';

final catalog = CoreCatalogItems.asCatalog();
final genUiManager = GenUiManager(catalog: catalog);

// Create the content generator with your preferred provider
final contentGenerator = DartanticContentGenerator(
  provider: Providers.google,  // or Providers.openai, Providers.anthropic, etc.
  catalog: catalog,
  systemInstruction: 'You are a helpful assistant that creates dynamic UIs.',
);

final genUiConversation = GenUiConversation(
  genUiManager: genUiManager,
  contentGenerator: contentGenerator,
);
```

## Supported Providers

The following AI providers are supported through dartantic_ai:

- **Google (Gemini):** `Providers.google`
- **OpenAI:** `Providers.openai`
- **Anthropic (Claude):** `Providers.anthropic`
- **Mistral:** `Providers.mistral`
- **Cohere:** `Providers.cohere`
- **Ollama:** `Providers.ollama`

## API Keys

API keys can be configured in dartantic_ai via environment variables:
- `GOOGLE_API_KEY` for Google/Gemini
- `OPENAI_API_KEY` for OpenAI
- `ANTHROPIC_API_KEY` for Anthropic
- etc.

## Adding Custom Tools

You can extend the AI's capabilities by providing additional tools:

```dart
final myCustomTool = DynamicAiTool<Map<String, Object?>>(
  name: 'my_custom_action',
  description: 'Performs a custom action.',
  parameters: S.object(properties: {
    'detail': S.string(),
  }),
  invokeFunction: (args) async {
    print('Custom action called with: $args');
    return {'status': 'ok'};
  },
);

final contentGenerator = DartanticContentGenerator(
  provider: Providers.google,
  catalog: catalog,
  systemInstruction: 'You are a helpful assistant.',
  additionalTools: [myCustomTool],
);
```

## Configuration

You can control which actions the AI is allowed to perform using `GenUiConfiguration`:

```dart
final contentGenerator = DartanticContentGenerator(
  provider: Providers.google,
  catalog: catalog,
  configuration: const GenUiConfiguration(
    actions: ActionsConfig(
      allowCreate: true,   // Allow creating new UI surfaces
      allowUpdate: true,   // Allow updating existing surfaces
      allowDelete: false,  // Disallow deleting surfaces
    ),
  ),
);
```

## Notes

- **Stateful Conversations:** The `DartanticContentGenerator` manages conversation history internally using dartantic_ai's `Chat` class. The `history` parameter in `sendRequest` is ignored.
- **Image Handling:** Currently, `ImagePart`s provided with only a `url` (without `bytes` or `base64` data) will be converted to a text description of the URL.
- **Structured Output:** Uses dartantic_ai's built-in support for structured output with JSON schemas, which works seamlessly with tool calling across all providers.
