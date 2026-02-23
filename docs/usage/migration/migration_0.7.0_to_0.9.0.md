# Migration Guide: GenUI v0.7.0 to v0.8.0

This release introduces significant changes to GenUI, primarily driven by the adoption of **A2UI v0.9**. This new protocol version represents a fundamental shift from a "Structured Output First" philosophy to a **"Prompt First"** approach, designed to be embedded directly in an LLM's system prompt.

In addition to protocol changes, the `genui` package architecture has been decoupled to provide greater flexibility. The `ContentGenerator` abstraction has been removed in favor of a clean separation between the **Engine** (`SurfaceController`), the **Facade** (`Conversation`), and the **Transport** (your connection to an LLM or Agent).

## Key Highlights

-   **A2UI v0.9 Adoption**: Complete protocol overhaul for better LLM performance and token efficiency.
-   **Architecture Decoupling**: `ContentGenerator` is gone. You now have full control over how you connect to your AI provider.
-   **Strict Validation**: The protocol now enforces strict validation, requiring specific system prompt instructions.
-   **Simplified Schema**: Components now use a flat structure (`"component": "Text"`) instead of nested keys (`"Text": {...}`).

---

## 1. Dependency Changes

The provider-specific packages that previously implemented `ContentGenerator` (e.g., `genui_dartantic`, `genui_google_generative_ai`, `genui_firebase_ai`) have been **removed**.

**Action**:
-   Remove dependencies on `genui_dartantic`, `genui_google_generative_ai`, etc., and replace them with direct usage of the underlying SDKs (e.g. `dartantic_ai`, `firebase_ai`, `google_generative_ai`, etc.).
-   If you were using `genui_a2ui`, it is still supported but has been updated to use the new `A2uiAgentConnector` pattern, and no longer has a `ContentGenerator`.

## 2. Replacing `ContentGenerator`

In v0.7.0, `ContentGenerator` handled everything: prompt construction, LLM calling, and parsing. In v0.8.0, this is split.

### The New Pattern: AI Client + `A2uiTransportAdapter`

You are now encouraged to implement a simple AI client that wraps your specific LLM SDK. `genui` provides `A2uiTransportAdapter` to bridge the gap between raw text streams coming from your LLM and the `SurfaceController`.

#### Example: Migrating from `DartanticContentGenerator`

**Old Way (v0.7.0):**
```dart
final generator = DartanticContentGenerator(apiKey: '...');
final controller = SurfaceController(generator: generator);
```

**New Way (v0.8.0):**
1.  **Define a simple client** (or use your SDK directly).
2.  **Wire it up** using `SurfaceController` (the engine) and `A2uiTransportAdapter` (parsing logic).

```dart
// 1. Initialize the Engine (holds the state of the UI)
final catalog = BasicCatalogItems.asCatalog();
final surfaceController = SurfaceController(catalogs: [catalog]);

// 2. Initialize the Adapter (handles A2UI parsing)
final adapter = A2uiTransportAdapter();

// 3. Connect them
adapter.messageStream.listen(surfaceController.handleMessage);

// 4. (Optional) Use a Facade for easier state management
// You can use the 'Conversation' facade which wraps the controller and a transport.
// OR manage the loop yourself as shown below:

// ... In your chat loop ...
await for (final chunk in myAiClient.sendStream(prompt)) {
  // Feed text chunks into the adapter
  adapter.addChunk(chunk);
}
```

This gives you complete control over the chat history, error handling, and retry logic, which was previously hidden inside `ContentGenerator`.

## 3. Reviewing System Prompts (CRITICAL)

A2UI v0.9 relies heavily on specific instructions being present in the system prompt. If you don't include the schema and the rules, the LLM will likely generate invalid v0.9 JSON.

**Action**: Ensure your system prompt includes:
1.  **The A2UI Schema**: Generated from your catalog.
2.  **The Standard Rules**: `BasicCatalogEmbed.basicCatalogRules`.

```dart
final promptBuilder = PromptBuilder.chat(
  catalog: catalog,
  instructions: 'You are a helpful assistant.',
);
final systemInstruction = promptBuilder.systemPrompt;
```

## 4. Protocol & Schema Changes

If you are manually constructing generic UI JSON or have hardcoded implementation details, distinct breaking changes exist.

### `beginRendering` is now `createSurface`
-   **Old**: `{ "beginRendering": { "root": "root", "styles": ... } }`
-   **New**: `{ "createSurface": { "surfaceId": "...", "catalogId": "...", "theme": ... } }`
    -   Requires `catalogId`.
    -   Use `theme` instead of `styles`.

### Component Definitions
-   **Old**: `{ "Text": { "text": "Hello" } }` (Key-based)
-   **New**: `{ "component": "Text", "text": "Hello" }` (Flat discriminator)

### Data Binding
-   **Old**: `{ "binding": "path/to/var" }` or `{ "literalString": "foo" }`
-   **New**: Just use an object with a `path` property `{ "path": "/path/to/var" }` for path resolution or standard JSON types for literals.

### Property Renames

| Component | Old Property | New Property |
| :--- | :--- | :--- |
| **Row / Column** | `distribution` | `justify` |
| **Row / Column** | `alignment` | `align` |
| **Modal** | `entryPointChild` | `trigger` |
| **Modal** | `contentChild` | `content` |
| **TextField** | `text` | `value` |
| **Many** | `usageHint` | `variant` |
| **Client Actions** | `userAction` | `action` |

## 5. Renames & Refactoring

To improve clarity and reduce verbosity, many classes have been renamed to remove the `GenUi` prefix or align with standard Flutter/Dart conventions.

| Old Name | New Name | Notes |
| :--- | :--- | :--- |
| `GenUiConversation` | `Conversation` | Collection of `ChatMessage`s. |
| `GenUiController` | `SurfaceController` | The core engine. |
| `GenUiSurface` | `Surface` | The widget that renders UI. |
| `GenUiHost` | `SurfaceHost` | Interface for the host environment. |
| `GenUiContext` | `SurfaceContext` | Context passed to components. |
| `GenUiTransport` | `Transport` | Interface for AI communication. |
| `ChatMessageWidget` | `ChatMessageView` | Widget for displaying messages. |
| `InternalMessageWidget` | `InternalMessageView` | Widget for internal system messages. |
| `GenUiFallback` | `FallbackWidget` | Error/Loading fallback. |
| `GenUiFunctionDeclaration` | `ClientFunction` | Tool declaration. |
| `GenUiPromptFragments` | (Removed) | Use `PromptBuilder` instead |
| `configureGenUiLogging` | `configureLogging` | |

## 6. Using `genai_primitives`

`genui` now builds upon the `genai_primitives` package for its core data structures. This unifies message types across the ecosystem.

-   **ChatMessage & Parts**: `ChatMessage`, `TextPart`, `DataPart`, etc., are now directly exported from `genai_primitives`.
-   **UI Parts as Extensions**: `UiPart` and `UiInteractionPart` are no longer direct subclasses of `Part`. Instead, they are helper views over `DataPart` with specific MIME types.

**Old Way:**
```dart
if (part is UiPart) {
  // ...
}
```

**New Way:**
```dart
if (part.isUiPart) {
  final uiPart = part.asUiPart!; // Returns a helper view
  // access uiPart.definition
}
```

## 7. Connecting to Remote Agents

If you are using `genui_a2ui` (A2A/A2UI adapter) to connect to a remote A2A/A2UI agent:

**Old Way:**
```dart
final connector = GenUiA2uiConnector(url: ...);
```

**New Way:**
Use `A2uiAgentConnector`.

```dart
final connector = A2uiAgentConnector(url: Uri.parse('...'));

// Sending a message
final responseText = await connector.connectAndSend(
  ChatMessage.user('Hello'),
  clientCapabilities: ...,
);

// Listening to the stream
connector.stream.listen((A2uiMessage message) {
  // Pass to your SurfaceController/Adapter
});
```

## 8. Example: Simple Chat Integration

See `examples/simple_chat/lib/chat_session.dart` for a complete reference implementation of the new pattern. This example uses `dartantic_ai` as the LLM provider.

### Quick Snippet

```dart
class ChatSession {
  final SurfaceController surfaceController;
  final A2uiTransportAdapter transportAdapter;

  ChatSession()
      : surfaceController = SurfaceController(catalogs: [BasicCatalogItems.asCatalog()]),
        transportAdapter = A2uiTransportAdapter() {

    // Connect Adapter -> Controller
    transportAdapter.messageStream.listen(surfaceController.handleMessage);

    // Listen for User Interactions
    surfaceController.onSubmit.listen((event) {
      // Handle button clicks / form submits
      sendMessage(event.toString());
    });
  }

  Future<void> sendMessage(String text) async {
    // 1. Send to LLM
    // 2. Stream response into transportAdapter
    await for (final chunk in llm.stream(text)) {
      transportAdapter.addChunk(chunk);
    }
  }
}
```
