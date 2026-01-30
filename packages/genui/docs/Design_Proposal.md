# GenUI API Design: Moving to "Bring Your Own LLM"

## Executive Summary

The current `genui` architecture relies on a `ContentGenerator` abstraction that wraps the LLM interaction, managing both the network connection and the state of the conversation. While this provides a unified interface for the framework, it creates friction for developers who want to integrate GenUI into existing applications with established LLM pipelines (e.g., Genkit, custom loops, or other AI SDKs).

With the shift to A2UI v0.9 and its "Prompt-First" philosophy—where the LLM streams text containing embedded JSON blocks—we have an opportunity to simplify the API. We can decouple the **content source** from the **content parsing and rendering**, allowing developers to "bring their own" LLM inference while still leveraging GenUI's powerful rendering capabilities.

This report proposes a **Unified Architecture** to achieve this goal, combining high-level ease of use with low-level composability.

## Current State

Currently, `GenUiConversation` requires a `ContentGenerator`:

```
abstract interface class ContentGenerator {
  Stream<A2uiMessage> get a2uiMessageStream;
  Stream<String> get textResponseStream;
  Future<void> sendRequest(ChatMessage message, {...});
  // ...
}
```

### Issues

1. **Inversion of Control:** The framework calls `sendRequest`, forcing the developer to implement the API call inside the framework's structure.
2. **State Management Duplication:** The `ContentGenerator` often replicates state management (history, tokens) that might already exist in the developer's app.
3. **Hidden Parsing:** The logic to extract A2UI messages from the text stream is buried within specific `ContentGenerator` implementations (e.g., `GoogleGenerativeAiContentGenerator`), making it hard to reuse just the parser.

## Design Goals

1. **Decoupling:** Separate the *source* of the stream (LLM) from the *consumer* (UI).
2. **Flexibility:** Allow any string stream (WebSocket, local model, mock, HTTP stream) to drive the UI.
3. **Simplicity:** Reduce the boilerplate needed to start rendering A2UI content.
4. **Bi-directionality:** maintain support for client-to-server `Action`s (events) and `ToolCall`s.

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
        GenUiController["GenUiController"]
        Transformer["A2uiParserTransformer"]
        A2uiMessageProcessor["A2uiMessageProcessor"]
        Catalog["Widget Catalog"]
        DataModel["DataModel"]
    end

    AppLogic -- "Initializes" --> GenUiConversation
    GenUiConversation -- "Wraps" --> GenUiController
    GenUiController -- "Owns" --> A2uiMessageProcessor
    GenUiController -- "Uses" --> Transformer

    A2uiMessageProcessor -- "Owns" --> DataModel

    AppLogic -- "Sends User Input" --> GenUiConversation
    GenUiConversation -- "Calls callback" --> ExternalLLM
    ExternalLLM -- "Returns chunks" --> GenUiController
    GenUiController -- "Pipes to" --> Transformer
    Transformer -- "Parses into events" --> A2uiMessageProcessor

    A2uiMessageProcessor -- "Notifies of updates" --> UIWidgets
    UIWidgets -- "Builds widgets using" --> Catalog
    UIWidgets -- "Reads/writes state via" --> DataModel
    UIWidgets -- "Sends UI events to" --> A2uiMessageProcessor

    A2uiMessageProcessor -- "Client events" --> GenUiController
    GenUiController -- "Forwards events" --> GenUiConversation
    GenUiConversation -- "Loops back" --> ExternalLLM
```

## Class Diagram

```mermaid
classDiagram
    class GenUiHost {
        <<interface>>
        +Stream~GenUiUpdate~ surfaceUpdates
        +ValueNotifier~UiDefinition?~ getSurfaceNotifier(String surfaceId)
        +Iterable~Catalog~ catalogs
        +Map~String, DataModel~ dataModels
        +DataModel dataModelForSurface(String surfaceId)
        +void handleUiEvent(UiEvent event)
    }

    class A2uiMessageProcessor {
        +void handleMessage(A2uiMessage message)
        +Stream~GenUiUpdate~ surfaceUpdates
        +Stream~ChatMessage~ onSubmit
        +Map~String, DataModel~ dataModels
        +DataModel dataModelForSurface(String surfaceId)
        +Map~String, Object?~ getClientDataModel()
        +ValueNotifier~UiDefinition?~ getSurfaceNotifier(String surfaceId)
        +void dispose()
    }

    class GenUiController {
        +void addChunk(String text)
        +void addMessage(A2uiMessage message)
        +Stream~String~ textStream
        +Stream~GenUiState~ stateStream
        +Stream~ChatMessage~ onClientEvent
        +void dispose()
    }

    class GenUiSurface {
        +GenUiHost host
        +String surfaceId
        +WidgetBuilder? defaultBuilder
    }

    class Catalog {
        +String? catalogId
        +Iterable~CatalogItem~ items
        +Schema definition
        +Widget buildWidget(CatalogItemContext context)
        +Catalog copyWith(List~CatalogItem~ newItems)
        +Catalog copyWithout(Iterable~CatalogItem~ itemNames)
    }

    class CatalogItem {
        +String name
        +Schema dataSchema
        +CatalogWidgetBuilder widgetBuilder
        +List~ExampleBuilderCallback~ exampleData
    }

    class DataModel {
        +void update(DataPath? path, Object? contents)
        +ValueNotifier subscribe(DataPath path)
        +ValueNotifier subscribeToValue(DataPath path)
        +T? getValue(DataPath path)
        +void bindExternalState(DataPath path, ValueListenable source)
        +void dispose()
    }

    GenUiHost <|.. A2uiMessageProcessor
    GenUiHost <|.. GenUiController
    GenUiController --> A2uiMessageProcessor : wraps
    GenUiSurface --> GenUiHost : uses
    A2uiMessageProcessor --> Catalog : uses
    Catalog --> CatalogItem : contains
    GenUiHost --> DataModel : manages
```

### 1. Transport Layer (`lib/src/transport/`)

This layer handles the pipeline from raw text input (from an LLM) to parsed UI events.

- **`GenUiController`**: The primary controller that manages the input stream (`addChunk`), the parsing pipeline, and the `A2uiMessageProcessor`. It provides a clean API for the application to feed data into the framework and listen for UI updates.
- **`A2uiParserTransformer`**: A robust stream transformer that parses mixed streams of text and A2UI JSON messages. It handles buffering, validation, and conversion of raw strings into structured `GenUiEvent`s.

### 2. UI State Management Layer (`lib/src/core/`)

This is the central nervous system of the package, orchestrating the state of all generated UI surfaces.

- **`A2uiMessageProcessor`**: The core state manager for the dynamic UI. It maintains a map of all active UI "surfaces", where each surface is represented by a `UiDefinition`. It takes a `GenUiConfiguration` object that can restrict AI actions (e.g., only allow creating surfaces, not updating or deleting them). The AI interacts with the manager by sending structured A2UI messages (parsed from the text stream), which the processor handles via `handleMessage()`. It exposes a stream of `GenUiUpdate` events (`SurfaceAdded`, `ComponentsUpdated`, `SurfaceRemoved`) so that the application can react to changes. It also owns the `DataModel` to manage the state of individual widgets (e.g., text field content) and acts as the `GenUiHost` for the `GenUiSurface` widget.

### 3. UI Model Layer (`lib/src/model/`)

This layer defines the data structures that represent the dynamic UI and the conversation.

- **`Catalog` and `CatalogItem`**: These classes define the registry of available UI components. The `Catalog` holds a list of `CatalogItem`s, and each `CatalogItem` defines a widget's name, its data schema, and a builder function to render it.
- **`A2uiMessage`**: A sealed class (`lib/src/model/a2ui_message.dart`) representing the commands the AI sends to the UI. It has the following subtypes:
  - `CreateSurface`: Signals the start of rendering for a surface, specifying the root component and optionally requests the client to attach the data model (`attachDataModel`).
  - `UpdateComponents`: Adds or updates components on a surface.
  - `UpdateDataModel`: Modifies data within the `DataModel` for a surface.
  - `DeleteSurface`: Requests the removal of a surface. The schemas for these messages are defined in `lib/src/model/a2ui_schemas.dart`.
- **`UiDefinition` and `UiEvent`**: `UiDefinition` represents a complete UI tree to be rendered, including the root widget and a map of all widget definitions. `UiEvent` is a data object representing a user interaction. `UserActionEvent` is a subtype used for events that should trigger a submission to the AI, like a button tap.
- **`ChatMessage`**: A sealed class representing the different types of messages in a conversation: `UserMessage`, `AiTextMessage`, `ToolResponseMessage`, `AiUiMessage`, `InternalMessage`, and `UserUiInteractionMessage`.
- **`DataModel` and `DataContext`**: The `DataModel` is a centralized, observable key-value store that holds the entire dynamic state of the UI. Widgets receive a `DataContext`, which is a view into the `DataModel` that understands the widget's current scope. This allows widgets to subscribe to changes in the data model and rebuild reactively. This separation of data and UI structure is a core principle of the architecture.

### 4. Widget Catalog Layer (`lib/src/catalog/`)

This layer provides a set of core, general-purpose UI widgets that can be used out-of-the-box.

- **`core_catalog.dart`**: Defines the `CoreCatalogItems`, which includes fundamental widgets like `AudioPlayer`, `Button`, `Card`, `CheckBox`, `Column`, `DateTimeInput`, `Divider`, `Icon`, `Image`, `List`, `Modal`, `MultipleChoice`, `Row`, `Slider`, `Tabs`, `Text`, `TextField`, and `Video`.
- **Widget Implementation**: Each core widget follows the standard `CatalogItem` pattern: a schema definition, a type-safe data accessor using an `extension type`, the `CatalogItem` instance, and the Flutter widget implementation.

### 5. UI Facade Layer (`lib/src/conversation/`)

This layer provides high-level widgets and controllers for easily building a generative UI application.

- **`GenUiConversation`**: The primary entry point for the package. This facade class encapsulates the `GenUiController` and manages the conversation loop. It abstracts away the complexity of piping events back to the `onSend` callback.
- **`GenUiSurface`**: The Flutter widget responsible for recursively building a UI tree from a `UiDefinition`. It listens for updates from a `GenUiHost` (implemented by `GenUiController` or `A2uiMessageProcessor`) for a specific `surfaceId` and rebuilds itself when the definition changes.

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
graph TD
    subgraph "User"
        UserInput("Provide Prompt")
        UserInteraction("Interact with UI")
    end

    subgraph "GenUI Framework"
        GenUiConversation("GenUiConversation")
        GenUiController("GenUiController")
        MessageProcessor("A2uiMessageProcessor")
        Transformer("A2uiParserTransformer")
        GenUiSurface("GenUiSurface")
    end

    UserInput -- "calls sendRequest()" --> GenUiConversation;
    GenUiConversation -- "calls onSend" --> ExternalLLM[External LLM];
    ExternalLLM -- "returns chunks" --> GenUiController;
    GenUiController -- "pipes to" --> Transformer;
    Transformer -- "parses events" --> MessageProcessor;
    MessageProcessor -- "updates state" --> GenUiSurface;
    GenUiSurface -- "renders UI" --> UserInteraction;
    UserInteraction -- "creates event" --> MessageProcessor;
    MessageProcessor -- "emits client event" --> GenUiController;
    GenUiController -- "forwards event" --> GenUiConversation;
    GenUiConversation -- "loops back" --> ExternalLLM;

## Surface Lifecycle & Cleanup

When multiple surfaces are generated in a conversation, `A2uiMessageProcessor` manages them according to a `SurfaceCleanupPolicy`. The default is `manual` (keep all surfaces until explicitly deleted), but `keepLatest` is common for chat interfaces where only the newest UI matters.

### Example: `keepLatest` Policy

```mermaid
sequenceDiagram
    participant LLM as External LLM
    participant Controller as GenUiController
    participant Processor as A2uiMessageProcessor
    participant UI as GenUiSurface (Manager)

    Note over Processor: Policy: keepLatest

    LLM->>Controller: "createSurface(id: 'A')"
    Controller->>Processor: CreateSurface('A')
    Processor->>UI: SurfaceAdded('A')
    UI->>UI: Render Surface A

    LLM->>Controller: "updateComponents(id: 'A', ...)"
    Controller->>Processor: UpdateComponents('A')
    Processor->>UI: ComponentsUpdated('A')
    UI->>UI: Update Surface A

    LLM->>Controller: "createSurface(id: 'B')"
    Controller->>Processor: CreateSurface('B')

    rect rgb(255, 240, 240)
        Note right of Processor: Policy Enforcement
        Processor->>UI: SurfaceRemoved('A')
        UI->>UI: Dispose Surface A
    end

    Processor->>UI: SurfaceAdded('B')
    UI->>UI: Render Surface B
```


## Detailed API Reference

### Core & Entry Points

These classes form the backbone of the GenUI integration in your app.

#### `lib/genui.dart`

**Purpose:** The main entry point for the package. Exports all public APIs.
**Used For:** Import this file to access all GenUI classes.
**Code Example:**

```
import 'package:genui/genui.dart';
```

#### `lib/src/transport/gen_ui_controller.dart`

**Purpose:** The primary controller for interacting with GenUI via
**Streaming Text**. **Used For:** Ideal for "Chat with LLM" scenarios where the model outputs a stream of text that may contain markdown, text, and JSON blocks mixed together.

**Code Example:**

```
final controller = GenUiController(
  catalogs: [CoreCatalogItems.asCatalog()],
  // OR provide an existing processor:
  // messageProcessor: myProcessor,
);
// Feed raw text chunks (e.g. from a streaming API response)
llmStream.listen((chunk) => controller.addChunk(chunk));
```

##### `GenUiController`

- `void addChunk(String text)`: Feed text from LLM.
- `void addMessage(A2uiMessage message)`: Feed a raw A2UI message directly (e.g. from tool output).
- `Stream<String> textStream`: Stream of text content (markdown) with UI JSON blocks stripped out.
- `Stream<GenUiState> stateStream`: Stream of UI updates (e.g. `SurfaceAdded`, `ComponentsUpdated`).
- `Stream<ChatMessage> onClientEvent`: Stream of user actions to send to LLM.
- `A2uiMessageProcessor get processor`: Access the underlying processor.
- `void dispose()`: Closes streams and cleans up resources.
- **Implements `GenUiHost`**: Can be passed directly to `GenUiSurface`.

#### `lib/src/core/a2ui_message_processor.dart`

**Purpose:** The central engine for processing Structured A2UI Messages.
**Used For:** Use this directly when you have structured data instead of raw text. Common scenarios include:

1. **Tool Use / Function Calling:** Your LLM returns parsed JSON arguments for a tool call.
2. **Non-LLM Backends:** Your server sends standard JSON payloads (like WebSockets).
3. **Static/Debug Content:** Rendering hardcoded component examples (e.g., `DebugCatalogView`).

**Code Example:**

```
final processor = A2uiMessageProcessor(catalogs: [myCatalog]);
// Feed a structured message object directly
processor.handleMessage(
  UpdateComponents(surfaceId: 'main', components: [...])
);
```

**Constructor Options used for Cleanup and Constraints:**

- `cleanupPolicy`: Strategies for removing old surfaces (`manual`, `keepLatest`, `keepLastN`).
- `maxSurfaces`: Maximum number of surfaces to keep when using `keepLastN`.
- `pendingUpdateTimeout`: Duration to wait for a `CreateSurface` message before discarding orphaned updates.

##### `A2uiMessageProcessor`

- `DataModel dataModelForSurface(String surfaceId)`: Access the data model for a specific surface.
- `Map<String, DataModel> get dataModels`: Map of all active data models.
- `Map<String, Object?> getClientDataModel()`: Returns a snapshot of the current data for all attached surfaces.
- `Stream<ChatMessage> get onSubmit`: Stream of user interactions (form submissions).
- `Stream<GenUiUpdate> get surfaceUpdates`: Stream of events when surfaces change.
- `ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId)`: Get the notifier for a surface's UI definition.
- `void dispose()`: Cleans up surface notifiers and streams.
- `void handleMessage(A2uiMessage message)`: Processes an incoming `A2uiMessage` (create, update, delete surface).
- `void handleUiEvent(UiEvent event)`: Handle a UI event from a surface.

##### `GenUiHost` (Interface)

- **The Contract:** Defines how `GenUiSurface` interacts with the backend logic, decoupling UI rendering from message processing.
- **Flexibility:** Allows `GenUiSurface` to work with *any* backend implementation:
  - Use `GenUiController` for streaming text (LLMs).
  - Use `A2uiMessageProcessor` for structured data (Tools, Databases).
  - Implement your own for custom backends.
- **API:**
- `DataModel dataModelForSurface(String surfaceId)`: Access the data model for a specific surface.
- `Iterable<Catalog> get catalogs`: The catalogs available to this host.
- `Map<String, DataModel> get dataModels`: Map of all active data models.
- `Stream<GenUiUpdate> get surfaceUpdates`: Stream of events when surfaces change.
- `ValueNotifier<UiDefinition?> getSurfaceNotifier(String surfaceId)`: Get the notifier for a surface's UI definition.
- `void handleUiEvent(UiEvent event)`: Handle a UI event from a surface.

##### `GenUiUpdate` (Sealed Class)

- Subclasses: `SurfaceAdded`, `ComponentsUpdated`, `SurfaceRemoved`.

#### `lib/src/core/genui_surface.dart`

**Purpose:** The Flutter widget that renders a dynamic UI surface.
**Used For:** Place this widget in your app where you want the AI-generated UI to appear.
**Code Example:**

```
GenUiSurface(
  host: myGenUiController,
  surfaceId: 'main-surface',
)
```

##### `GenUiSurface` (StatefulWidget)

- Constructor: `GenUiSurface({required GenUiHost host, required String surfaceId, WidgetBuilder? defaultBuilder})`
- The `defaultBuilder` renders a placeholder while the surface definition is empty or loading.

#### `lib/src/widgets/gen_ui_surface_manager.dart`

**Purpose:** Manages a collection of surfaces.
**Used For:** Automatically displaying all active surfaces (e.g. if the LLM creates multiple).

##### `GenUiSurfaceManager`

- `host`: The `GenUiHost` to watch.
- `layoutBuilder`: Custom layout for the list of surfaces.
- `surfaceBuilder`: Custom builder for individual surfaces (e.g. to wrap them).

#### `lib/src/facade/gen_ui_conversation.dart`

**Purpose:** High-level abstraction for managing a chat conversation with GenUI support.
**Used For:** Building a chat app where the view binds to a list of messages.
**Code Example:**

```
final conversation = GenUiConversation(
  controller: myController,
  onSend: (msg, history) => myLLMClient.sendMessage(msg),
);
```

**`GenUiConversation`**

- `ValueListenable<List<ChatMessage>> get conversation`: The reactive list of chat messages.
- `ValueListenable<bool> get isProcessing`: Whether the conversation is currently waiting for a response.
- `Future<void> sendRequest(ChatMessage message)`: Sends a message to the LLM.
- **Callbacks:** `onSurfaceAdded`, `onComponentsUpdated`, `onSurfaceDeleted`, `onTextResponse`, `onError`.

### Data Models & Protocol

These classes define the data structures and protocol used by GenUI.

#### `lib/src/model/data_model.dart`

**Purpose:** The reactive data store for GenUI surfaces.
**Used For:** Managing state shared between components.

##### `DataModel`

- `void update(DataPath? path, Object? contents)`: Updates data.
- `ValueNotifier<T?> subscribe<T>(DataPath path)`: Subscribe to changes.
- `ValueNotifier<T?> subscribeToValue<T>(DataPath path)`: Subscribe to changes at a specific path only.
- `T? getValue<T>(DataPath path)`: Retrieve a static value without subscribing.
- `void bindExternalState<T>({required DataPath path, required ValueListenable<T> source, bool twoWay})`: Bind an external `ValueNotifier` to the data model.
- `void dispose()`: Disposes resources.

##### `DataPath`

- Parses and represents paths like `/user/name` or relative paths.

##### `DataContext`

- A view of the `DataModel` scoped to a specific path (used by widgets).

#### `lib/src/model/ui_models.dart`

**Purpose:** Core models for UI definition and events.

##### `UiDefinition`

- Represents the state of a surface: `catalogId`, `components` map, `theme`.

##### `UiEvent` & `UserActionEvent`

- Represents events triggered by the user (e.g. button click).

##### `Component`

- Data class for a single widget instance (type, id, properties).

#### `lib/src/model/a2ui_message.dart`

**Purpose:** Defines the messages exchanged in the A2UI protocol.
**Used For:** Parsing server responses.

##### `A2uiMessage` (Sealed Class)

- Subclasses: `CreateSurface`, `UpdateComponents`, `UpdateDataModel`, `DeleteSurface`.
- `factory fromJson(JsonMap json)`: Parses any A2UI message.

#### `lib/src/model/gen_ui_events.dart`

**Purpose:** Events related to the generation process (tokens, tools, text).
**Used For:** Monitoring the stream from the LLM.

##### `GenUiEvent` (Sealed Class)

- Subclasses: `TextEvent`, `A2uiMessageEvent`, `ToolStartEvent`, `ToolEndEvent`, `TokenUsageEvent`.

#### `lib/src/model/a2ui_client_capabilities.dart`

**Purpose:** Describes the client's supported catalogs.
**Used For:** Sending client capabilities to the server/LLM.

##### `A2UiClientCapabilities`

- Hold list of `supportedCatalogIds`.

#### `lib/src/model/a2ui_schemas.dart`

**Purpose:** Provides pre-defined JSON schemas for common data types and validation.
**Used For:** Defining `CatalogItem` schemas concisely.

##### `A2uiSchemas`

- Static methods like `stringReference()`, `numberReference()`, `action()`, `updateComponentsSchema()`, etc.

#### `lib/src/model/chat_message.dart`

**Purpose:** Re-exports `genai_primitives` for chat message models.
**Used For:** Formatting messages for the UI or LLM.

##### `ChatMessageFactories`

- Helpers like `userText` and `modelText`.

#### `lib/src/model/parts.dart` & `parts/ui.dart`

**Purpose:** Extensions to `ChatMessage` parts to support UI payloads.
**Used For:** Handling multimodal messages that include UI definitions.

##### `UiPart`

- Wraps a `UiDefinition` in a message part.

##### `UiInteractionPart`
- Wraps a user interaction event in a message part.

### Catalogs & Component Infrastructure

These classes handle the definition and building of UI components.

#### `lib/src/model/catalog.dart`

**Purpose:** Represents a collection of `CatalogItem`s.
**Used For:** Grouping widgets to provide to the `A2uiMessageProcessor`.

##### `Catalog`

- `Schema get definition`: Generates the full JSON schema for the catalog (for the LLM).
- `Widget buildWidget(...)`: Builds a widget from the catalog given context.
- `Catalog copyWith(List<CatalogItem> newItems)`: Returns a new catalog with items added/replaced.
- `Catalog copyWithout(Iterable<CatalogItem> itemNames)`: Returns a new catalog with items removed.

#### `lib/src/model/catalog_item.dart`

**Purpose:** Defines a single UI component type.
**Used For:** Creating custom components.
**Code Example:**

```
final myItem = CatalogItem(
  name: 'MyWidget',
  dataSchema: S.object(...),
  widgetBuilder: (context) => MyWidget(...),
);
```

##### `CatalogItem`

- Properties: `name`, `dataSchema`, `widgetBuilder`, `exampleData`.

##### `CatalogItemContext`
- Context object passed to `widgetBuilder`, containing `data`, `dataContext`, `buildChild`, etc.

#### `lib/src/catalog/core_catalog.dart`

**Purpose:** Defines the `CoreCatalogItems` class which provides the standard set of A2UI components.
**Used For:** Use `CoreCatalogItems.asCatalog()` to get a ready-to-use catalog for your `A2uiMessageProcessor`.
**Code Example:**

```
final processor = A2uiMessageProcessor(
  catalogs: [CoreCatalogItems.asCatalog()],
);
```

##### `CoreCatalogItems`

- `static Catalog asCatalog()`: Creates a `Catalog` containing all core items (Button, Text, Column, etc.) with the standard A2UI catalog ID.

#### `lib/src/core/functions.dart`

**Purpose:** Registry of client-side functions available to the A2UI expression system.
**Used For:** Register custom functions that the AI can invoke or use in expressions.

##### `FunctionRegistry`

- `void register(String name, ClientFunction function)`: Add a custom function.
- `Object? invoke(String name, List<Object?> args)`: Call a function.
- `void registerStandardFunctions()`: Registers the default set of functions (e.g. `required`, `regex`, `length`, etc.).

### Utilities & Helpers

#### `lib/src/transport/a2ui_parser_transformer.dart`

**Purpose:** A stream transformer that parses raw text chunks into `GenUiEvent`s.
**Used For:** Piping an LLM text stream into the `GenUiController`.

##### `A2uiParserTransformer`

- Transforms `Stream<String>` \-\> `Stream<GenUiEvent>`. Handles JSON block extraction and balancing.

#### `lib/src/core/expression_parser.dart`

**Purpose:** Evaluates `${...}` expressions and logic in A2UI definitions.
**Used For:** Internal use for resolving data bindings and executing client-side logic/validation.

##### `ExpressionParser`

- `Object? parse(String input)`: Parses a string with potential expressions.
- `bool evaluateLogic(JsonMap expression)`: Evaluates a logic object (and/or/not).
- `Object? evaluateFunctionCall(JsonMap callDefinition)`: Evaluates a function call map.

#### `lib/src/utils/json_block_parser.dart`

**Purpose:** Robustly extracts JSON from potentially messy LLM output.
**Used For:** Parsing JSON blocks even if surrounded by markdown or incomplete.

##### `JsonBlockParser`

- `static Object? parseFirstJsonBlock(String text)`
- `static List<Object> parseJsonBlocks(String text)`
- `static String stripJsonBlock(String text)`

#### `lib/src/core/widget_utilities.dart`

**Purpose:** Helpers for data binding and widgets.

##### `DataContextExtensions`

- `subscribeToValue<T>`: Helper to create a `ValueNotifier` from a data path or literal.

##### `OptionalValueBuilder`
- Helper widget to build children only when a value is non-null.

#### `lib/src/core/prompt_fragments.dart`

**Purpose:** Contains static strings useful for prompting the LLM.
**Used For:** Injecting instructions into the system prompt.

##### `GenUiPromptFragments`

- `basicChat`: A standard prompt block instructing the LLM to use UI tools.

#### `lib/src/model/standard_catalog_embed.dart`

**Purpose:** embedded text resource.
**Used For:** Accessing the standard catalog rules as a string for prompts.

#### `lib/src/primitives/logging.dart`

**Purpose:** Internal logging. **Used For:** Access `genUiLogger`.

#### `lib/src/primitives/cancellation.dart`

**Purpose:** Simple cancellation token pattern.
**Used For:** Cancelling streaming operations.

##### `CancellationSignal`

- Methods: `cancel()`, `addListener()`.

#### `lib/src/primitives/constants.dart`

**Purpose:** Shared constants.
**Used For:** Accessing `standardCatalogId`.

#### `lib/src/primitives/simple_items.dart`

**Purpose:** Typedefs and simple utilities.
**Used For:** `JsonMap` typedef, `generateId()`.

#### `lib/src/widgets/gen_ui_fallback.dart`

**Purpose:** Generic fallback widget for errors/loading.
**Used For:** Displaying errors within the GenUI area.

##### `GenUiFallback`

- Parameters: `error`, `isLoading`, `onRetry`.

#### `lib/src/facade/widgets/chat_primitives.dart`

**Purpose:** Basic widgets for displaying chat messages.
**Used For:** Quickly building a chat interface.

##### `ChatMessageView`

- Displays a simple user or model text message.

##### `InternalMessageView`
- Displays system/debug messages.

### Tooling & Integrations

#### `lib/src/facade/direct_call_integration/model.dart`

**Purpose:** Models for parsing tool calls when using "Direct Tool Call" LLM APIs (like OpenAI function calling).

##### `ToolCall`

- Represents a call to a tool with name and arguments.

##### `GenUiFunctionDeclaration`
- Represents the schema of a tool to be sent to the LLM.

#### `lib/src/facade/direct_call_integration/utils.dart`

**Purpose:** Utilities for integrating with LLM tool-calling APIs.

##### `genUiTechPrompt`

- Generates a system prompt explaining how to use the UI tools.

##### `catalogToFunctionDeclaration`
- Converts a `Catalog` into a `GenUiFunctionDeclaration` for the LLM.

#### `lib/src/development_utilities/catalog_view.dart`

**Purpose:** A widget for visualizing all items in a catalog using their example data.
**Used For:** Development and debugging of custom catalogs.

##### `DebugCatalogView`

- Renders a list of all components in the provided `Catalog` by rendering their `exampleData`.

### Standard Catalog Items

These are the standard widgets available in the `CoreCatalog`:

* `audioPlayer`
* `button`
* `card`
* `checkBox`
* `choicePicker`
* `column`
* `dateTimeInput`
* `divider`
* `icon`
* `image`
* `imageFixedSize`
* `list`
* `modal`
* `row`
* `slider`
* `tabs`
* `text`
* `textField`
* `video`

#### `lib/src/catalog/core_widgets/widget_helpers.dart`

**Purpose:** Utilities for building standard widget structures like lists with templates.
**Used For:** Used internally by `Column`, `Row`, `List` to handle children building.

##### `ComponentChildrenBuilder`

- A widget that builds children from either an explicit list of IDs or a data-bound template.

##### `buildWeightedChild`

- Helper to wrap a child in `Flexible` if the component definition has a 'weight' property.
