# `flutter_genui` Package Implementation

This document provides a comprehensive overview of the architecture, purpose, and implementation of the `flutter_genui` package.

## Purpose

The `flutter_genui` package provides the core framework for building Flutter applications with dynamically generated user interfaces powered by large language models (LLMs). It enables developers to create conversational UIs where the interface is not static or predefined, but is instead constructed by an AI in real-time based on the user's prompts and the flow of the conversation.

The package supplies the essential components for managing the conversation, interacting with the AI model, defining a vocabulary of UI widgets, and rendering the dynamic UI.

## Architecture

The package is designed with a layered architecture, separating concerns to create a flexible and extensible framework.

### 1. AI Client Layer (`lib/src/ai_client/`)

This layer is responsible for all communication with the generative AI model.

- **`AiClient`**: An abstract interface defining the contract for a client that interacts with an AI model. This allows for different LLM backends to be implemented.
- **`GeminiAiClient`**: The default implementation of `AiClient`. It handles the complexities of interacting with the Gemini API, including model configuration, retry logic with exponential backoff, and tool management. It uses a "forced tool calling" approach, where the model is required to call a function to produce its output.
- **`AiTool`**: An abstract class for defining tools that the AI can invoke. These tools are the bridge between the AI and the application's capabilities. The `DynamicAiTool` provides a convenient way to create tools from simple functions.

### 2. Conversation Management Layer (`lib/src/core/`)

This is the central nervous system of the package, orchestrating the entire generative UI process.

- **`GenUiManager`**: The main orchestrator. It manages the conversation history, sends prompts to the `AiClient`, processes the AI's responses (which are UI manipulation actions), and updates the UI. It maintains the state of the conversation and the rendered UI "surfaces".
- **`ConversationWidget` and `GenUiChat`**: Flutter widgets that render the chat history. `GenUiManager` can be configured with a `GenUiStyle` to use `ConversationWidget` for a flexible, free-form layout, or `GenUiChat` for a more traditional chat-style interface.
- **`UiEventManager`**: A utility to coalesce UI events. Change events (like text field changes) are collected and sent in a batch with the next action event (like a button tap). This prevents excessive calls to the AI model during rapid user input.

### 3. UI Model Layer (`lib/src/model/`)

This layer defines the data structures that represent the dynamic UI and the conversation.

- **`Catalog` and `CatalogItem`**: These classes define the registry of available UI components. The `Catalog` holds a list of `CatalogItem`s, and each `CatalogItem` defines a widget's name, its data schema, and a builder function to render it.
- **`UiDefinition` and `UiEvent`**: `UiDefinition` represents a complete UI tree to be rendered, including the root widget and a map of all widget definitions. `UiEvent` is a data object representing a user interaction (e.g., a button tap), which is sent back to the `GenUiManager`.
- **`ChatMessage`**: A sealed class representing the different types of messages in the conversation history: `UserMessage`, `AssistantMessage`, `UiResponseMessage`, `ToolResponseMessage`, and `InternalMessage`.
- **`SurfaceWidget`**: The Flutter widget responsible for recursively building the UI tree from a `UiDefinition`. It uses the provided `Catalog` to find the correct widget builder for each node in the tree.

### 4. Widget Catalog Layer (`lib/src/catalog/`)

This layer provides a set of core, general-purpose UI widgets that can be used out-of-the-box.

- **`core_catalog.dart`**: Defines the `coreCatalog`, which includes fundamental widgets like `Column`, `Text`, `ElevatedButton`, `TextField`, `CheckboxGroup`, `RadioGroup`, and `Image`.
- **Widget Implementation**: Each core widget follows the standard `CatalogItem` pattern: a schema definition, a type-safe data accessor using an `extension type`, the `CatalogItem` instance, and the Flutter widget implementation.

## How It Works: The Generative UI Cycle

1. **User Input**: The user enters a text prompt in the UI.
2. **Prompt Dispatch**: The UI calls `GenUiManager.sendUserPrompt()`.
3. **Conversation Update**: The `GenUiManager` adds the user's prompt as a `UserMessage` to the conversation history.
4. **AI Invocation**: The `GenUiManager` calls `aiClient.generateContent()`, passing the full conversation history and an `outputSchema`. The `outputSchema` defines the structure of the expected response, which includes a list of UI actions (`add`, `update`, `delete`).
5. **Model Processing**: The `GeminiAiClient` sends the request to the LLM. The LLM, guided by the system prompt and the schemas of the available widgets (tools), decides how to respond.
6. **Tool Call Response**: The model generates a response that calls the internal "output" tool. The arguments to this tool call conform to the `outputSchema` and contain the instructions for manipulating the UI.
7. **Action Processing**: The `GenUiManager` receives the structured response. It iterates through the list of actions.
   - For an **`add`** action, it creates a new `UiResponseMessage` and adds it to the chat history.
   - For an **`update`** action, it finds the existing `UiResponseMessage` with the matching `surfaceId` and replaces it with the new definition.
   - For a **`delete`** action, it removes the corresponding `UiResponseMessage` from the chat history.
8. **UI Rendering**: The `_uiDataStreamController` in the `GenUiManager` emits the updated chat history. The `ConversationWidget` or `GenUiChat` widget rebuilds, and its `ListView` now includes the new or updated `UiResponseMessage`.
9. **Dynamic UI Build**: The `SurfaceWidget` widget receives the `UiDefinition` and recursively builds the Flutter widget tree using the `Catalog`.
10. **User Interaction**: The user interacts with the newly generated UI (e.g., clicks a button).
11. **Event Dispatch**: The widget's handler calls a `dispatchEvent` function, creating a `UiEvent`. This is passed up to the `SurfaceWidget`.
12. **Event Handling**: The `SurfaceWidget`'s `onEvent` callback is triggered, which calls `UiEventManager.add()`. The `UiEventManager` coalesces change events until an action event occurs, at which point it calls `GenUiManager.handleEvents`.
13. **Cycle Repeats**: The `GenUiManager` wraps the incoming `UiEvent`s into `ToolResultPart`s inside a new `UserMessage`, adds it to the conversation history, and calls the AI again to get an updated UI, thus continuing the cycle.
