# flutter_genui_dartantic

This package provides the integration between `flutter_genui` and the Dartantic AI framework. It allows you to use the power of multiple AI providers (OpenAI, Google, Anthropic, etc.) through Dartantic to generate dynamic user interfaces in your Flutter applications.

## Features

- **DartanticAiClient:** An implementation of `AiClient` that connects to the Dartantic AI framework.
- **DartanticContentConverter:** Converts between the generic `ChatMessage` and the `dartantic_interface` specific `ChatMessage` classes.
- **DartanticSchemaAdapter:** Adapts schemas from `json_schema_builder` to the `json_schema` format used by Dartantic.

## Getting Started

To use this package, you will need to have your preferred AI provider configured (API keys via environment variables as per Dartantic conventions).

Then, you can create an instance of `DartanticAiClient` and pass it to your `GenUiConversation`:

```dart
final genUiManager = GenUiManager(catalog: catalog);
final aiClient = DartanticAiClient(
  provider: 'google', // or 'openai', 'anthropic', etc.
  model: 'gemini-2.5-flash', // or 'gemini-2.5-pro', 'gpt-4o', etc.
  systemInstruction: 'You are a helpful assistant.',
  tools: genUiManager.getTools(),
);
final genUiConversation = GenUiConversation(
  genUiManager: genUiManager,
  aiClient: aiClient,
  ...
);
```

## Supported Providers

Dartantic supports multiple AI providers out of the box:
- OpenAI
- Google (Gemini)
- Anthropic (Claude)
- Mistral
- Cohere
- Ollama
- And more

See the [Dartantic documentation](https://docs.dartantic.ai) for the complete list and configuration details.
