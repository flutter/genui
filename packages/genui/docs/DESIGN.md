# `genui` Package Implementation

This document provides a comprehensive overview of the architecture, purpose, and implementation of the `genui` package.

## Purpose

The `genui` package provides the core framework for building Flutter applications with dynamically generated user interfaces powered by large language models (LLMs). It enables developers to create conversational UIs where the interface is not static or predefined, but is instead constructed by an AI in real-time based on the user's prompts and the flow of the conversation.

The package supplies the essential components for managing the state of the dynamic UI, interacting with the AI model, defining a vocabulary of UI widgets, and rendering the UI surfaces. The primary entry point for this package is the `GenUiConversation`.

## Architecture

The package is designed with a layered architecture, separating concerns to create a flexible and extensible framework. The diagram below shows how the `genui` package integrates with the developer's application and the backend LLM.

```mermaid
graph TD
    subgraph "Developer's Application"
        AppLogic["App Logic"]
        UIWidgets["UI Widgets<br>(e.g., GenUiSurface)"]
        ExternalLLM["External LLM Client"]
    end

    subgraph "genui Package"
        GenUiConversation["GenUiConversation (Facade)"]
        GenUiTransport["GenUiTransport (Interface)"]
        A2uiTransportAdapter["A2uiTransportAdapter"]
        GenUiController["GenUiController (Engine)"]
        Transformer["A2uiParserTransformer"]
        Catalog["Widget Catalog"]
        DataModel["DataModel"]
    end

    AppLogic -- "Initializes" --> GenUiConversation
    GenUiConversation -- "Uses" --> GenUiTransport
    GenUiConversation -- "Manages" --> GenUiController

    AppLogic -- "Sends User Input" --> GenUiConversation
    GenUiConversation -- "Delegates to" --> GenUiTransport
    GenUiTransport -- "Calls callback" --> ExternalLLM
    ExternalLLM -- "Returns chunks" --> A2uiTransportAdapter
    A2uiTransportAdapter -- "Pipes to" --> Transformer
    Transformer -- "Parses into events" --> A2uiTransportAdapter
    A2uiTransportAdapter -- "Stream<A2uiMessage>" --> GenUiTransport
    GenUiTransport -- "Pipes to" --> GenUiConversation
    GenUiConversation -- "Dispatches to" --> GenUiController

    GenUiController -- "Notifies of updates" --> UIWidgets
    UIWidgets -- "Builds widgets using" --> Catalog
    UIWidgets -- "Reads/writes state via" --> DataModel
    UIWidgets -- "Sends UI events to" --> GenUiController

    GenUiController -- "Client events" --> GenUiConversation
    GenUiConversation -- "Loops back" --> GenUiTransport
```

### 1. Transport Layer (`lib/src/transport/` and `lib/src/interfaces/`)

This layer handles the pipeline from raw text input (from an LLM) to parsed UI events.

- **`GenUiTransport`**: An interface defining the contract for sending and receiving messages.
- **`A2uiTransportAdapter`**: The default implementation of `GenUiTransport`. It manages the input stream (`addChunk`), the parsing pipeline, and communicates with the `GenUiConversation`. It uses the `A2uiParserTransformer` to parse streams.
- **`A2uiParserTransformer`**: A robust stream transformer that parses mixed streams of text and A2UI JSON messages. It handles buffering, validation, and conversion of raw strings into structured `GenUiEvent`s.

### 2. UI State Management Layer (`lib/src/engine/`)

This is the central nervous system of the package, orchestrating the state of all generated UI surfaces.

- **`GenUiController`**: The core state manager for the dynamic UI (formerly `A2uiMessageProcessor`). It maintains a map of all active UI "surfaces", where each surface is represented by a `UiDefinition`. It takes a `GenUiConfiguration` object that can restrict AI actions. The AI interacts with the manager by sending structured A2UI messages, which the controller handles via `handleMessage()`. It exposes a stream of `GenUiUpdate` events (`SurfaceAdded`, `ComponentsUpdated`, `SurfaceRemoved`) so that the application can react to changes. It also owns the `DataModel` to manage the state of individual widgets and implements `GenUiHost` to provide `GenUiContext`s for `GenUiSurface` widgets.

### 3. UI Model Layer (`lib/src/model/`)

This layer defines the data structures that represent the dynamic UI and the conversation.

- **`Catalog` and `CatalogItem`**: These classes define the registry of available UI components. The `Catalog` holds a list of `CatalogItem`s, and each `CatalogItem` defines a widget's name, its data schema, and a builder function to render it.
- **`A2uiMessage`**: A sealed class (`lib/src/model/a2ui_message.dart`) representing the commands the AI sends to the UI. It has the following subtypes:
  - `CreateSurface`: Signals the start of rendering for a surface, specifying the root component.
  - `UpdateComponents`: Adds or updates components on a surface.
  - `UpdateDataModel`: Modifies data within the `DataModel` for a surface.
  - `DeleteSurface`: Requests the removal of a surface.
    The schemas for these messages are defined in `lib/src/model/a2ui_schemas.dart`.
- **`UiDefinition` and `UiEvent`**: `UiDefinition` represents a complete UI tree to be rendered, including the root widget and a map of all widget definitions. `UiEvent` is a data object representing a user interaction. `UserActionEvent` is a subtype used for events that should trigger a submission to the AI, like a button tap.
- **`ChatMessage`**: A sealed class representing the different types of messages in a conversation: `UserMessage`, `AiTextMessage`, `ToolResponseMessage`, `AiUiMessage`, `InternalMessage`, and `UserUiInteractionMessage`.
- **`DataModel` and `DataContext`**: The `DataModel` is a centralized, observable key-value store that holds the entire dynamic state of the UI. Widgets receive a `DataContext`, which is a view into the `DataModel` that understands the widget's current scope. This allows widgets to subscribe to changes in the data model and rebuild reactively. This separation of data and UI structure is a core principle of the architecture.

### 4. Widget Catalog Layer (`lib/src/catalog/`)

This layer provides a set of core, general-purpose UI widgets that can be used out-of-the-box.

- **`core_catalog.dart`**: Defines the `CoreCatalogItems`, which includes fundamental widgets like `AudioPlayer`, `Button`, `Card`, `CheckBox`, `Column`, `DateTimeInput`, `Divider`, `Icon`, `Image`, `List`, `Modal`, `MultipleChoice`, `Row`, `Slider`, `Tabs`, `Text`, `TextField`, and `Video`.
- **Widget Implementation**: Each core widget follows the standard `CatalogItem` pattern: a schema definition, a type-safe data accessor using an `extension type`, the `CatalogItem` instance, and the Flutter widget implementation.

### 5. UI Facade Layer (`lib/src/conversation/`)

This layer provides high-level widgets and controllers for easily building a generative UI application.

- **`GenUiConversation`**: The primary entry point for the package. This facade class encapsulates the `GenUiController` (engine) and the `GenUiTransport`. It manages the conversation loop, piping messages between the transport and the engine.
- **`GenUiSurface`**: The Flutter widget responsible for recursively building a UI tree from a `UiDefinition`. It listens for updates from a `GenUiContext` (typically obtained from a `GenUiHost` like `A2uiMessageProcessor`) and rebuilds itself when the definition changes.

### 6. Primitives Layer (`lib/src/primitives/`)

This layer contains basic utilities used throughout the package.

- **`logging.dart`**: Provides a configurable logger (`genUiLogger`).
- **`simple_items.dart`**: Defines a type alias for `JsonMap`.

### 7. Direct Call Integration (`lib/src/facade/direct_call_integration/`)

This directory provides utilities for a more direct interaction with the AI model, potentially bypassing some of the higher-level abstractions of `GenUiConversation`. It includes:

- **`model.dart`**: Defines data models for direct API calls.
- **`utils.dart`**: Contains utility functions to assist with direct calls.

## How It Works: The Generative UI Cycle

The `GenUiConversation` simplifies the process of creating a generative UI by managing the conversation loop and the interaction with the AI.

```mermaid
sequenceDiagram
    participant User
    participant AppLogic as "App Logic"
    participant GenUiConversation
5. **AI Invocation**: The `GenUiConversation` invokes the `onSend` callback.
6. **External LLM Call**: The application's `onSend` logic calls the external LLM.
7. **Streaming Response**: As data arrives from the LLM, the application feeds it into `GenUiController.addChunk()`.
8. **Parsing Pipeline**: `A2uiParserTransformer` parses the chunks, identifying A2UI messages (JSON blocks) and plain text.
9. **State Update**: `A2uiMessageProcessor` processes A2UI messages, updating the `DataModel` and `UiDefinition`.
10. **UI Rendering**: `GenUiSurface` receives updates from the controller and rebuilds the UI.
11. **Client Event**: User interactions trigger `GenUiController.onClientEvent`, which `GenUiConversation` listens to.
12. **Loop**: `GenUiConversation` automatically calls `onSend` again with the new event message, perpetuating the conversation.
