# genui_dartantic

This package provides the integration between `genui` and the Dartantic AI
package. It allows you to use multiple AI providers (OpenAI, Anthropic, Google,
Mistral, Cohere, Ollama) to generate dynamic user interfaces in your Flutter
applications.

## Features

- **DartanticContentGenerator:** An implementation of `ContentGenerator` that
  uses the dartantic_ai package to connect to various AI providers.
- **Multi-Provider Support:** Use any provider supported by dartantic_ai
  including OpenAI, Anthropic, Google, Mistral, Cohere, and Ollama.
- **DartanticContentConverter:** Converts between GenUI `ChatMessage` types and
  dartantic_ai `ChatMessage` types.
- **Schema Adaptation:** Converts schemas from `json_schema_builder` to the
  `json_schema` format used by dartantic_ai.
- **Additional Tools:** Supports adding custom `AiTool`s to extend the AI's
  capabilities via the `additionalTools` parameter.
- **Error Handling:** Exposes an `errorStream` to listen for and handle any
  errors during content generation.

## Getting Started

To use this package, you will need to configure API keys for your chosen
provider (see API Keys section below).

Then, you can create an instance of `DartanticContentGenerator` and pass it to
your `GenUiConversation`:

```dart
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:genui/genui.dart';
import 'package:genui_dartantic/genui_dartantic.dart';

final catalog = CoreCatalogItems.asCatalog();
final genUiManager = GenUiManager(catalog: catalog);

// Example of a custom tool
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
  provider: Providers.google,  // or Providers.openai, Providers.anthropic, etc.
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

## Supported Providers

The following AI providers are supported through dartantic_ai:

- **Google (Gemini):** `GoogleProvider`
- **OpenAI:** `OpenAIProvider`
- **Anthropic (Claude):** `AnthropicProvider`
- **Mistral:** `MistralProvider`
- **Cohere:** `CohereProvider`
- **Ollama:** `OllamaProvider`

## API Keys

API keys can be configured in dartantic_ai via environment variables:
- `GEMINI_API_KEY` for Google/Gemini
- `OPENAI_API_KEY` for OpenAI
- `ANTHROPIC_API_KEY` for Anthropic
- etc.

## Configuration

You can control which actions the AI is allowed to perform using
`GenUiConfiguration`:

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

- **Stateless Design:** The `DartanticContentGenerator` is stateless and does
  not maintain internal conversation history. It uses the `history` parameter
  passed to `sendRequest` by `GenUiConversation`, converting GenUI messages to
  dartantic format via `DartanticContentConverter`.
- **Image Handling:** Currently, `ImagePart`s provided with only a `url`
  (without `bytes` or `base64` data) will be sent to the model as a text
  description of the URL, as the image data is not automatically fetched by the
  converter.
- **Structured Output:** Uses dartantic_ai's built-in support for structured
  output with JSON schemas, which works with tool calling across all providers.
