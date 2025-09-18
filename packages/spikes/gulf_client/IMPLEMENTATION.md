# GULF Client Implementation Details

This document describes the purpose, design, and implementation of the GULF (Generative UI Language Framework) client, a Flutter package for rendering dynamic user interfaces from a streaming, JSONL-based format.

## 1. Purpose

The primary purpose of the GULF client is to enable the creation of server-driven user interfaces in a Flutter application. An LLM or other backend service can generate a UI definition in a simple, line-delimited JSON (JSONL) format, which is then streamed to the client. The client interprets this stream and renders a native Flutter UI, allowing for highly dynamic and flexible applications where the UI can be changed without shipping a new version of the client application.

The protocol is designed to be "LLM-friendly," meaning its structure is straightforward and declarative, making it easy for a generative model to produce.

## 2. Design Rationale and Context

The GULF protocol and this client were designed to support several key requirements for building dynamic, AI-driven UIs.

*   **JSONL Stream Processing:** The client must consume a stream of JSONL objects, parsing each line as a distinct message.
*   **Progressive Rendering:** The UI should render incrementally as component and data model definitions arrive, without waiting for the entire stream to finish.
*   **LLM-Friendly "Property Bag" Schema:** The protocol uses a single "property bag" structure for all components, making it simple for generative models to create valid UI definitions.
*   **Decoupled UI and Data:** The protocol separates the UI structure (`components`) from the application data (`dataModelNodes`), allowing them to be managed and updated independently.
*   **Flattened Adjacency List Model:** The UI and data trees are represented as flattened maps of nodes, where relationships are defined by ID references. The client is responsible for reconstructing these hierarchies.
*   **Data Binding:** The client must resolve data bindings in component properties (e.g., `value: { "path": "/user/name" }`) by looking up the corresponding data in the data model.

### Alternatives Considered

During the design phase, adapting a generic JSON-to-Widget library was considered but ultimately rejected. No existing library was designed to handle the specific JSONL streaming, progressive rendering, and flattened data model semantics of the GULF protocol. The required adaptation layer would have effectively become a custom interpreter anyway, adding an unnecessary dependency. A bespoke client implementation was chosen for a cleaner and more efficient result.

## 3. Core Concepts & Design

The framework is built on a few core concepts that separate the UI definition from its concrete implementation.

*   **Streaming UI Definition (JSONL):** The UI is not defined in a single, large file. Instead, it's described by a stream of small, atomic JSON messages, each on a new line. This allows the UI to be built and updated incrementally as data arrives from the server, improving perceived performance.
*   **Component Tree:** The UI is represented as a tree of abstract `Component`s. Each component has a unique `id`, a `type` (e.g., "Column", "Text"), and properties. Components reference each other by their IDs to form a hierarchy (e.g., a "Column" component has a `children` property listing the IDs of its child components).
*   **Decoupled Data Model:** The application's state is held in a `DataModelNode` tree, separate from the component tree. This separation of concerns allows the UI and the data to be updated independently. Components can bind to data nodes using a simple path syntax (e.g., `"/user/name"`).
*   **Extensible Widget Registry:** The client itself does not contain any Flutter widget implementations for the component types. Instead, it uses a `WidgetRegistry`. The developer using the package must provide concrete `CatalogWidgetBuilder` functions that map a component `type` (e.g., "Card") to a Flutter `Widget` (e.g., a `Card` widget). This makes the renderer fully extensible and customizable.

## 4. Architecture

### Project Structure
```txt
packages/spikes/gulf_client/
├── lib/
│   ├── gulf_client.dart      # Main library file, exports public APIs
│   ├── src/
│   │   ├── core/
│   │   │   ├── interpreter.dart    # GulfInterpreter class
│   │   │   └── widget_registry.dart # WidgetRegistry class
│   │   ├── models/
│   │   │   ├── component.dart      # Component data model
│   │   │   ├── data_node.dart      # DataModelNode data model
│   │   │   └── stream_message.dart # GulfStreamMessage and related classes
│   │   └── widgets/
│   │       ├── gulf_provider.dart   # InheritedWidget for event handling
│   │       └── gulf_view.dart       # Main rendering widget
│   └── pubspec.yaml
└── example/
    └── ... (A simple example app)
```

### Data Flow

The data flows in one direction, from the server stream to the final rendered Flutter widgets.

```mermaid
sequenceDiagram
    participant StreamSource
    participant GulfInterpreter
    participant GulfView
    participant WidgetRegistry
    participant FlutterEngine

    StreamSource->>+GulfInterpreter: JSONL Stream (line by line)
    GulfInterpreter->>GulfInterpreter: Parse JSON into StreamMessage
    GulfInterpreter->>GulfInterpreter: Handle message (e.g., ComponentUpdate)
    GulfInterpreter->>GulfInterpreter: Update internal component/data buffers
    GulfInterpreter-->>-GulfView: notifyListeners()
    GulfView->>+GulfInterpreter: Get rootComponentId
    GulfView->>GulfView: Start building widget tree from root
    loop For each component in tree
        GulfView->>+GulfInterpreter: Get Component object by ID
        GulfView->>GulfView: Resolve data bindings against Data Model
        GulfView->>+WidgetRegistry: Get builder for component.type
        WidgetRegistry-->>-GulfView: Return WidgetBuilder function
        GulfView->>GulfView: Call builder with resolved properties
    end
    GulfView-->>-FlutterEngine: Return final Widget tree for rendering
```

The core components are:
1.  **Input Stream (`Stream<String>`):** A stream of JSONL strings is the raw input.
2.  **`GulfInterpreter`:** This class is the core of the client. It consumes the stream, parses each JSONL message, and maintains the state of the component tree and the data model in simple `Map`s. It acts as the central state store.
3.  **`ChangeNotifier`:** The interpreter uses Flutter's `ChangeNotifier` mixin to notify listeners whenever the UI state changes (e.g., a new component is added or the root is set).
4.  **`GulfView`:** This is the main Flutter widget. It listens to the `GulfInterpreter`. When notified, it rebuilds its child widget tree.
5.  **`_LayoutEngine`:** A private, internal class that recursively walks the component tree, starting from the root component ID provided by the interpreter.
6.  **`WidgetRegistry`:** For each component it encounters, the `_LayoutEngine` looks up the corresponding builder function in the `WidgetRegistry` provided by the developer.
7.  **Flutter Widgets:** The builder function is executed, which returns a concrete Flutter widget. The engine assembles these widgets into the final tree that gets rendered on the screen.
8.  **`GulfProvider`:** An `InheritedWidget` is used to pass down event handlers (like button press callbacks) to the deeply nested widgets without "prop drilling."

## 5. Protocol Details

The client processes four types of messages, defined in `stream_message.dart`.

*   `{"messageType": "StreamHeader", "version": "1.0.0"}`
    *   **Purpose:** The first message in any stream. It identifies the protocol and version.
*   `{"messageType": "ComponentUpdate", "components": [...]}`
    *   **Purpose:** Adds or updates one or more components in the UI tree. The `components` value is a list of `Component` objects. This is how the UI is built and modified.
*   `{"messageType": "DataModelUpdate", "nodes": [...]}`
    *   **Purpose:** Adds or updates one or more nodes in the data model.
*   `{"messageType": "UIRoot", "root": "root_id", "dataModelRoot": "data_root_id"}`
    *   **Purpose:** Signals to the client that it has enough information to perform the initial render. It specifies the ID of the root component for the UI tree and the root of the data model.

## 6. Key Implementation Components

### `GulfInterpreter` (The State Manager)

This class is the heart of the client, consuming the raw JSONL stream and managing the canonical UI and data state.

-   **Input:** Takes a `Stream<String>` of JSONL messages.
-   **State:** Maintains two primary data structures:
    -   `_components`: A `Map<String, Component>` storing all UI components by their ID.
    -   `_dataModelNodes`: A `Map<String, DataModelNode>` storing all data nodes by their ID.
-   **Logic:**
    1.  Listens to the stream and calls `processMessage` for each line.
    2.  Deserializes the JSON into a `GulfStreamMessage` object.
    3.  Updates the `_components` or `_dataModelNodes` maps based on the message type.
    4.  When a `UIRoot` message is received, it sets the `_rootComponentId` and a flag `_isReadyToRender`.
    5.  Calls `notifyListeners()` to signal to `GulfView` that it's time to update.
-   **Public API:**
    - `Component? getComponent(String id)`
    - `DataModelNode? getDataNode(String id)`
    - `Object? resolveDataBinding(String path)`: Traverses the data model tree to find the value at the given path.

### `WidgetRegistry` (The Extension Point)

-   This is a simple class holding a `Map<String, CatalogWidgetBuilder>`.
-   The `register(String type, CatalogWidgetBuilder builder)` method allows the application developer to associate a component type string with a function that builds a Flutter widget.
-   The `getBuilder(String type)` method is used by the layout engine to retrieve the correct builder during the rendering process.

### `GulfView` & `_LayoutEngine` (The Rendering Pipeline)

-   **`GulfView`** is a `StatefulWidget` that:
    1.  Listens to the `GulfInterpreter` for changes.
    2.  Calls `setState()` in response to notifications, triggering a rebuild.
    3.  Renders a `CircularProgressIndicator` until `interpreter.isReadyToRender` is true.
    4.  Once ready, it renders the `_LayoutEngine`, wrapping it in a `GulfProvider` to make the `onEvent` callback available.

-   **`_LayoutEngine`** is a `StatelessWidget` that performs the recursive build:
    1.  The `build` method starts the process by calling `_buildNode` with the root component ID.
    2.  The `_buildNode(String componentId)` method:
        a. Fetches the `Component` from the interpreter using its ID.
        b. Looks up the `CatalogWidgetBuilder` from the `WidgetRegistry` using the component's `type`.
        c. Resolves all properties for the component. This involves checking if a value is a literal (e.g., `"literalString": "Hello"`) or a data binding (`"path": "/user/name"`) and resolving it if necessary.
        d. Recursively calls `_buildNode` for all child component IDs (found in `component.child` or `component.children.explicitList`).
        e. Handles templated lists (defined in `component.children.template`) by iterating over a list from the data model and building a widget for each item.
        f. Finally, it calls the retrieved builder function, passing it the `BuildContext`, the original `Component`, the resolved properties, and a map of the already-built child widgets.

## 7. Example Usage (`example/lib/main.dart`)

The example demonstrates how to use the client:

1.  **Create a `WidgetRegistry`:** An instance is created in the `_ExampleViewState`.
2.  **Register Builders:** In `initState`, builders for "Column", "Row", "Text", "Image", etc., are registered. Each builder is a function that takes the component metadata and returns a configured Flutter widget.
3.  **Instantiate `GulfInterpreter`:** When the user clicks "Render JSONL", a new `GulfInterpreter` is created and fed the lines from the text field via a `StreamController`.
4.  **Use `GulfView`:** The `GulfView` widget is placed in the widget tree, and is passed the `interpreter` and the `registry`. It automatically listens and renders the UI when the interpreter is ready.
