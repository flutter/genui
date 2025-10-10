# A2UI Client Implementation Details

This document describes the purpose, design, and implementation of the A2UI (Generative UI Language Framework) client, a Flutter package for rendering dynamic user interfaces from a streaming, JSONL-based format.

## 1. Purpose

The primary purpose of the A2UI client is to enable the creation of server-driven user interfaces in a Flutter application. An LLM or other backend service can generate a UI definition in a simple, line-delimited JSON (JSONL) format, which is then streamed to the client. The client interprets this stream and renders a native Flutter UI, allowing for highly dynamic and flexible applications where the UI can be changed without shipping a new version of the client application.

The protocol is designed to be "LLM-friendly," meaning its structure is straightforward and declarative, making it easy for a generative model to produce.

## 2. Design Rationale and Context

The A2UI protocol and this client were designed to support several key requirements for building dynamic, AI-driven UIs.

- **JSONL Stream Processing:** The client must consume a stream of JSONL objects, parsing each line as a distinct message.
- **Progressive Rendering:** The UI should render incrementally as component and data model definitions arrive, without waiting for the entire stream to finish.
- **Type-Safe Schema with Discriminated Unions:** The protocol uses a discriminated union pattern for components (`componentProperties`). This provides a structured and type-safe way to define UI components, making it easier for both servers to generate and clients to parse.
- **Decoupled UI and Data:** The protocol separates the UI structure (`components`) from the application data (`dataModel`), allowing them to be managed and updated independently.
- **Path-Based Data Model:** The data model is a JSON-like object, and updates are performed using a simple path syntax (e.g., `user.address.street`), which is a common and flexible pattern for dynamic data.
- **Data Binding:** The client must resolve data bindings in component properties (e.g., `value: { "path": "user.name" }`) by looking up the corresponding data in the data model.

### Alternatives Considered

During the design phase, adapting a generic JSON-to-Widget library was considered but ultimately rejected. No existing library was designed to handle the specific JSONL streaming, progressive rendering, and discriminated union semantics of the A2UI protocol. The required adaptation layer would have effectively become a custom interpreter anyway, adding an unnecessary dependency. A bespoke client implementation was chosen for a cleaner and more efficient result.

## 3. Core Concepts & Design

The framework is built on a few core concepts that separate the UI definition from its concrete implementation.

- **Streaming UI Definition (JSONL):** The UI is not defined in a single, large file. Instead, it's described by a stream of small, atomic JSON messages, each on a new line. This allows the UI to be built and updated incrementally as data arrives from the server, improving perceived performance.
- **Component Tree:** The UI is represented as a tree of abstract `Component`s. Each component has a unique `id` and a `componentProperties` object that defines its type and behavior (e.g., a "Text" component has `TextProperties`). Components reference each other by their IDs to form a hierarchy.
- **Decoupled Data Model:** The application's state is held in a single, JSON-like `Map<String, dynamic>` object, separate from the component tree. This separation of concerns allows the UI and the data to be updated independently. Components can bind to data using a simple path syntax (e.g., `"user.name"`).
- **Extensible Widget Registry:** The client itself does not contain any Flutter widget implementations for the component types. Instead, it uses a `WidgetRegistry`. The developer using the package must provide concrete `CatalogWidgetBuilder` functions that map a component `type` (e.g., "CardProperties") to a Flutter `Widget` (e.g., a `Card` widget). This makes the renderer fully extensible and customizable.

## 4. Architecture

### Project Structure

```txt
packages/spikes/a2ui_client/
├── lib/
│   ├── a2ui_client.dart      # Main library file, exports public APIs
│   ├── src/
│   │   ├── core/
│   │   │   ├── a2ui_agent_connector.dart # Connects to an A2UI Agent endpoint
│   │   │   ├── interpreter.dart          # A2uiInterpreter class
│   │   │   └── widget_registry.dart      # WidgetRegistry class
│   │   ├── models/
│   │   │   ├── chat_message.dart   # Chat message data model
│   │   │   ├── component.dart      # Component data models
│   │   │   └── stream_message.dart # A2uiStreamMessage and related classes
│   │   ├── utils/
│   │   │   ├── json_utils.dart     # JSON parsing utilities
│   │   │   └── logger.dart         # Logging utilities
│   │   └── widgets/
│   │       ├── component_properties_visitor.dart # Resolves component properties
│   │       ├── a2ui_provider.dart   # InheritedWidget for event handling
│   │       └── a2ui_view.dart       # Main rendering widget
│   └── pubspec.yaml
└── example/
    └── ... (A simple example app)
```

### Data Flow

The data flows in one direction, from the server stream to the final rendered Flutter widgets.

```mermaid
sequenceDiagram
    participant StreamSource
    participant A2uiInterpreter
    participant A2uiView
    participant WidgetRegistry
    participant FlutterEngine

    StreamSource->>+A2uiInterpreter: JSONL Stream (line by line)
    A2uiInterpreter->>A2uiInterpreter: Parse JSON into StreamMessage
    A2uiInterpreter->>A2uiInterpreter: Handle message (e.g., ComponentUpdate)
    A2uiInterpreter->>A2uiInterpreter: Update internal component/data buffers
    A2uiInterpreter-->>-A2uiView: notifyListeners()
    A2uiView->>+A2uiInterpreter: Get rootComponentId
    A2uiView->>A2uiView: Start building widget tree from root
    loop For each component in tree
        A2uiView->>+A2uiInterpreter: Get Component object by ID
        A2uiView->>A2uiView: Resolve data bindings against Data Model
        A2uiView->>+WidgetRegistry: Get builder for component.componentProperties.runtimeType
        WidgetRegistry-->>-A2uiView: Return WidgetBuilder function
        A2uiView->>A2uiView: Call builder with resolved properties
    end
    A2uiView-->>-FlutterEngine: Return final Widget tree for rendering
```

The core components are:

1.  **Input Stream (`Stream<String>`):** A stream of JSONL strings is the raw input. This can be from a manual source or the `A2uiAgentConnector`.
2.  **`A2uiAgentConnector`:** Connects to an A2UI Agent endpoint, handles the A2A protocol, and provides the stream of A2UI protocol lines.
3.  **`A2uiInterpreter`:** This class is the core of the client. It consumes the stream, parses each JSONL message, and maintains the state of the component tree and the data model. It acts as the central state store.
4.  **`ChangeNotifier`:** The interpreter uses Flutter's `ChangeNotifier` mixin to notify listeners whenever the UI state changes (e.g., a new component is added or the data model is updated).
5.  **`A2uiView`:** This is the main Flutter widget. It listens to the `A2uiInterpreter`. When notified, it rebuilds its child widget tree.
6.  **`_LayoutEngine`:** A private, internal class that recursively walks the component tree, starting from the root component ID provided by the interpreter.
7.  **`ComponentPropertiesVisitor`**: A visitor class used by the `_LayoutEngine` to resolve the properties of a component, handling data bindings.
8.  **`WidgetRegistry`:** For each component it encounters, the `_LayoutEngine` looks up the corresponding builder function in the `WidgetRegistry` provided by the developer.
9.  **Flutter Widgets:** The builder function is executed, which returns a concrete Flutter widget. The engine assembles these widgets into the final tree that gets rendered on the screen.
10. **`A2uiProvider`:** An `InheritedWidget` is used to pass down event handlers (like button press callbacks) to the deeply nested widgets without "prop drilling."

## 5. Protocol Details

The client processes four types of messages, defined in `stream_message.dart`.

- `{"streamHeader": {"version": "1.0.0"}}`
  - **Purpose:** The first message in any stream. It identifies the protocol and version.
- `{"componentUpdate": {"components": [...]}}`
  - **Purpose:** Adds or updates one or more components in the UI tree. The `components` value is a list of `Component` objects. This is how the UI is built and modified.
- `{"dataModelUpdate": {"path": "...", "contents": ...}}`
  - **Purpose:** Adds or updates a part of the data model at a given `path`.
- `{"beginRendering": {"root": "root_id"}}`
  - **Purpose:** Signals to the client that it has enough information to perform the initial render. It specifies the ID of the root component for the UI tree.

## 6. Key Implementation Components

### `A2uiInterpreter` (The State Manager)

This class is the heart of the client, consuming the raw JSONL stream and managing the canonical UI and data state.

- **Input:** Takes a `Stream<String>` of JSONL messages.
- **State:** Maintains two primary data structures:
  - `_components`: A `Map<String, Component>` storing all UI components by their ID.
  - `_dataModel`: A `Map<String, dynamic>` representing the entire JSON data model.
- **Logic:**
  1.  Listens to the stream and calls `processMessage` for each line.
  2.  Deserializes the JSON into a `A2uiStreamMessage` object.
  3.  Updates the `_components` map or the `_dataModel` map based on the message type.
  4.  When a `BeginRendering` message is received, it sets the `_rootComponentId` and a flag `_isReadyToRender`.
  5.  Calls `notifyListeners()` to signal to `A2uiView` that it's time to update.
- **Public API:**
  - `Component? getComponent(String id)`
  - `Object? resolveDataBinding(String path)`: Traverses the data model to find the value at the given path.

### `A2uiAgentConnector`

Connects to an A2UI Agent endpoint, which is a server that speaks the A2A (Agent-to-Agent) protocol and provides A2UI UI streams.

- **Input:** Takes a `Uri` for the agent endpoint.
- **Logic:**
  1.  Uses the `a2a` package to handle the underlying communication.
  2.  Fetches an `AgentCard` with metadata about the agent.
  3.  Sends a message to the agent and receives a stream of events.
  4.  Extracts A2UI messages from the A2A data parts, transforms them, and pushes them into a `Stream<String>`.
- **Output:** Provides a `Stream<String>` of A2UI JSONL messages that can be consumed by the `A2uiInterpreter`.

### `WidgetRegistry` (The Extension Point)

- This is a simple class holding a `Map<String, CatalogWidgetBuilder>`.
- The `register(String type, CatalogWidgetBuilder builder)` method allows the application developer to associate a component type string (e.g., `TextProperties`) with a function that builds a Flutter widget.
- The `getBuilder(String type)` method is used by the layout engine to retrieve the correct builder during the rendering process.

### `A2uiView` & `_LayoutEngine` (The Rendering Pipeline)

- **`A2uiView`** is a `StatefulWidget` that:

  1.  Listens to the `A2uiInterpreter` for changes.
  2.  Calls `setState()` in response to notifications, triggering a rebuild.
  3.  Renders a `CircularProgressIndicator` until `interpreter.isReadyToRender` is true.
  4.  Once ready, it renders the `_LayoutEngine`, wrapping it in a `A2uiProvider` to make the `onEvent` callback available.

- **`_LayoutEngine`** is a `StatelessWidget` that performs the recursive build:
  1.  The `build` method starts the process by calling `_buildNode` with the root component ID.
  2.  The `_buildNode(String componentId)` method:
      a. Fetches the `Component` from the interpreter using its ID.
      b. Looks up the `CatalogWidgetBuilder` from the `WidgetRegistry` using the `runtimeType` of the `component.componentProperties` object.
      c. Uses a `ComponentPropertiesVisitor` to resolve all properties for the component. This involves checking if a value is a literal or a data binding and resolving it if necessary.
      d. Recursively calls `_buildNode` for all child component IDs.
      e. Handles templated lists by iterating over a list from the data model and building a widget for each item.
      f. Finally, it calls the retrieved builder function, passing it the `BuildContext`, the original `Component`, the resolved properties, and a map of the already-built child widgets.

### `ComponentPropertiesVisitor`

- A visitor class that traverses the properties of a component.
- Its main responsibility is to resolve `BoundValue` objects, which can be either a literal value or a path to a value in the data model.
- This decouples the property resolution logic from the layout engine.

## 7. Example Usage (`example/lib/main.dart`)

The example demonstrates how to use the client in two ways: `ManualInputView` and `AgentConnectionView`. The application state is managed by an `AgentState` class, which is a `ChangeNotifier` that is provided to the widget tree using the `provider` package.

### `ManualInputView`

1.  **Create a `WidgetRegistry`:** An instance is created in the `_ManualInputViewState`.
2.  **Register Builders:** In `initState`, builders for "Column", "Row", "Text", "Image", etc., are registered. Each builder is a function that takes the component metadata and returns a configured Flutter widget.
3.  **Instantiate `A2uiInterpreter`:** When the user clicks "Render JSONL", a new `A2uiInterpreter` is created and fed the lines from the text field via a `StreamController`.
4.  **Use `A2uiView`:** The `A2uiView` widget is placed in the widget tree, and is passed the `interpreter` and the `registry`. It automatically listens and renders the UI when the interpreter is ready.

### `AgentConnectionView`

1.  **`AgentState`**: The `AgentState` class holds the `A2uiAgentConnector`, `A2uiInterpreter`, and `AgentCard`. It is provided to the widget tree using `ChangeNotifierProvider`.
2.  **Instantiate `A2uiAgentConnector`**: The `AgentState` class creates a `A2uiAgentConnector` and fetches the agent card when it is initialized.
3.  **`SettingsView`**: A separate settings view allows the user to change the agent URL and re-fetch the agent card.
4.  **Send Message**: The user can send a message to the agent, which will then start streaming back the A2UI UI definition.
5.  **Use `A2uiView`**: The `AgentConnectionView` consumes the `AgentState` to get the `A2uiInterpreter` and `WidgetRegistry`, and then uses the `A2uiView` widget to render the UI.
