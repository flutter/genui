# **`gulf_client` Design Document**

## **1. Overview**

This document outlines the detailed design for a new Flutter package, `gulf_client`. The purpose of this package is to provide a client-side implementation for the "GULF Streaming UI Protocol". It will be responsible for parsing a JSONL stream of UI commands, managing state, and rendering a dynamic Flutter UI.

The design is heavily inspired by the existing `gulf_client` package but is architected from the ground up to specifically support the semantics and schema of the GULF protocol. The core goal is to create a robust, maintainable, and performant client that enables progressive UI rendering directly from an AI-generated stream.

## **2. Detailed Analysis of the Goal**

The primary goal is to build a Flutter package that can interpret and render a UI defined a simplified GULF protocol. This protocol differs significantly from the GenUI Streaming Protocol (GULF) implemented by the `gulf_client`.

### **Key Requirements & Protocol Features**

- **JSONL Stream Processing:** The client must be able to consume a stream of JSONL objects, parsing each line as a distinct message.
- **Progressive Rendering:** The UI should be rendered incrementally as component and data model definitions arrive. The client should not wait for the entire stream to finish before displaying the UI.
- **LLM-Friendly "Property Bag" Schema:** The client's data models must conform to the GULF protocol's schema, which uses a single "property bag" structure for all components and a discriminator field (`type` or `messageType`) to differentiate them.
- **Decoupled UI and Data:** The protocol separates the UI structure (`components`) from the application data (`dataModelNodes`). The client must manage these two models independently and link them via data bindings.
- **Flattened Adjacency List Model:** Both the UI tree and the data model tree are represented as flattened maps of nodes, where relationships are defined by ID references. The client must be able to reconstruct these hierarchical relationships.
- **Data Binding:** The client must resolve data bindings specified in component properties (e.g., `value: { "path": "/user/name" }`) by looking up the corresponding data in the data model tree.

### **Comparison with `gulf_client`**

Understanding the differences with the existing `gulf_client` is crucial for this refactor:

| Feature              | `gulf_client` (GULF)                               | `gulf_client` (GULF Protocol)                      | Rationale for New Implementation                                                                                                        |
| :------------------- | :------------------------------------------------- | :------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| **UI Definition**    | Client-defined `WidgetCatalog` sent to server.     | Server-streamed `Component` definitions.           | The fundamental contract is inverted. GULF has no concept of a client-side catalog, making the `gulf_client`'s core logic incompatible. |
| **Component Schema** | Each widget has a unique, strictly defined schema. | A single "property bag" schema for all components. | Requires a completely different approach to deserialization and property resolution.                                                    |
| **State/Data Model** | A single, simple `initialState` JSON object.       | A flattened, tree-like `dataModelNodes` structure. | The data model is more complex and requires a dedicated engine to traverse and resolve paths.                                           |
| **Message Types**    | `Layout`, `LayoutRoot`, `StateUpdate`.             | `ComponentUpdate`, `DataModelUpdate`, `UIRoot`.    | The stream's message semantics are different, requiring new parsing and handling logic.                                                 |

Given these fundamental differences, a new, purpose-built implementation is necessary to ensure a clean, maintainable, and accurate client for the GULF protocol.

## **3. Alternatives Considered**

### **Alternative 1: Adapt the existing `gulf_client`**

- **Description:** Modify the `gulf_client` to support both GULF and the GULF protocol, likely through extensive conditional logic.
- **Pros:** Potential for some code reuse in the widget building and rendering layers.
- **Cons:** The core architectural differences (especially the catalog-based approach vs. the streamed-component approach) are too significant. The codebase would become convoluted with `if (protocol == 'SGULF')` checks, making it difficult to maintain and debug. The data model and message parsing logic are entirely different and would require separate pathways anyway.
- **Decision:** Rejected. The cost of maintaining a complex, multi-protocol client outweighs the benefits of minimal code reuse. A clean slate is preferable.

### **Alternative 2: Use a generic JSON-to-Widget library**

- **Description:** Find a third-party library that can render Flutter widgets from a generic JSON schema and build an adaptation layer on top of it.
- **Pros:** Could potentially save time on the widget-building logic itself.
- **Cons:** No existing library is designed to handle the specific JSONL streaming, progressive rendering, and flattened data model semantics of the GULF protocol. The adaptation layer would need to manage the stream, buffer nodes, reconstruct the tree, and resolve data bindings, effectively becoming a custom interpreter anyway. This adds an unnecessary dependency and couples our implementation to the limitations of the generic library.
- **Decision:** Rejected. The GULF protocol is specialized enough to warrant a bespoke client implementation for a clean and efficient result.

## **4. Detailed Design**

The `gulf_client` will be architected around a few core components that work together to process the stream and render the UI.

### **4.1. Project Structure**

The package will be organized as follows:

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
    └── ... (A simple example app similar to gulf_client's)
```

### **4.2. Core Components & Data Flow**

The data will flow from the stream through the `GulfInterpreter`, which will then be consumed by the `GulfView` to build the widget tree.

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

### **4.3. Class Definitions**

#### **`GulfInterpreter` (`interpreter.dart`)**

This will be the heart of the client. It consumes the raw JSONL stream and makes sense of it.

- **Class:** `class GulfInterpreter with ChangeNotifier`
- **Inputs:** `Stream<String> stream`
- **State:**
  - `Map<String, Component> components = {}`
  - `Map<String, DataModelNode> dataModelNodes = {}`
  - `String? rootComponentId`
  - `String? dataModelRootId`
  - `bool isReadyToRender = false`
- **Logic:**
  - The constructor will listen to the input stream.
  - A `processMessage(String jsonl)` method will parse the JSON and deserialize it into an `GulfStreamMessage` object.
  - It will use a `switch` statement on `message.messageType` to delegate to private handler methods:
    - `_handleComponentUpdate(message)`: Iterates through `message.components` and adds them to the `_components` map.
    - `_handleDataModelUpdate(message)`: Iterates through `message.nodes` and adds them to the `_dataModelNodes` map.
    - `_handleUIRoot(message)`: Sets `_rootComponentId` and `_dataModelRootId`. Sets `isReadyToRender = true`.
  - After any state change, it will call `notifyListeners()`.
- **Public API:**
  - `Component? getComponent(String id)`
  - `DataModelNode? getDataNode(String id)`
  - `Object? resolveDataBinding(String path)`: A crucial method that traverses the data model tree starting from `dataModelRootId` to find the value at the given path.

#### **Data Models (`models/*.dart`)**

These will be simple, immutable data classes created using the `freezed` package to represent the JSON structures from the protocol. This provides value equality, `copyWith`, and exhaustive `when` methods for free.

- **`GulfStreamMessage`**: A freezed union type to represent the different message types.

  ```dart
  @freezed
  class GulfStreamMessage with _$GulfStreamMessage {
    const factory GulfStreamMessage.streamHeader({required String version}) = _StreamHeader;
    const factory GulfStreamMessage.componentUpdate({required List<Component> components}) = _ComponentUpdate;
    // ... etc.
  }
  ```

- **`Component`**: A freezed class representing the component "property bag". All properties from the schema will be fields here, most of them nullable.
- **`DataModelNode`**: A freezed class representing a node in the data model tree.

#### **`WidgetRegistry` (`widget_registry.dart`)**

This class maps a component `type` string to a function that builds a Flutter `Widget`.

- **Class:** `class WidgetRegistry`
- **State:** `Map<String, CatalogWidgetBuilder> _builders = {}`
- **Logic:**
  - `register(String type, CatalogWidgetBuilder builder)`: Adds a builder to the map.
  - `getBuilder(String type)`: Retrieves a builder.
- **Note:** Unlike `gulf_client`, this registry does _not_ build a `WidgetCatalog` object, as that concept doesn't exist in the GULF protocol. It is purely a client-side mapping.

#### **`GulfView` (`gulf_view.dart`)**

This is the main `StatefulWidget` that developers will use. It orchestrates the rendering process.

- **Class:** `class GulfView extends StatefulWidget`
- **Inputs:**
  - `GulfInterpreter interpreter`
  - `WidgetRegistry registry`
  - `ValueChanged<Event>? onEvent`
- **Logic:**
  - Its `State` object will listen to the `interpreter`. When the interpreter notifies, `setState` is called to trigger a rebuild.
  - The `build` method will check `interpreter.isReadyToRender`. If false, it shows a `CircularProgressIndicator`.
  - If ready, it will start the recursive build process, beginning with `_buildNode(context, interpreter.rootComponentId)`.
  - It will wrap the entire tree in an `GulfProvider` to make the `onEvent` callback available to descendant widgets (like buttons).

#### **Layout and Data Binding Engine (Private methods in `_GulfViewState`)**

- **`_buildNode(BuildContext context, String componentId)`**:
  1.  Gets the `Component` object from the interpreter.
  2.  Gets the `WidgetBuilder` from the registry.
  3.  Resolves all properties for the component. This involves checking for data bindings in properties like `value`.
  4.  Recursively builds all child widgets specified by ID in properties like `child` or `children.explicitList`.
  5.  Calls the retrieved `WidgetBuilder` with the resolved properties and built children.
- **`_resolveProperties(Component component)`**:
  1.  Creates a mutable copy of the component's properties.
  2.  For each property, checks if it's a data binding (e.g., `value.path` is not null).
  3.  If it is, it calls `interpreter.resolveDataBinding(path)` to get the real value.
  4.  It replaces the binding object with the resolved value in the property map.
  5.  Returns the fully resolved map of properties.

## **5. Summary of Design**

The proposed design establishes a clean, reactive architecture for a Flutter client that implements the GULF Streaming UI Protocol.

- **`GulfInterpreter`** acts as the "brain", processing the stream and managing the canonical UI and data state.
- **`GulfView`** acts as the "renderer", listening to the interpreter and translating its state into a Flutter widget tree.
- **`WidgetRegistry`** provides the necessary mapping from abstract component types to concrete Flutter widgets.
- **Immutable Data Models** (using `freezed`) ensure predictable state management and reduce bugs.

This approach directly addresses the requirements of the GULF protocol, including its streaming nature, LLM-friendly schema, and decoupled data model, while following Dart and Flutter best practices.

## **6. References**

- [GenUI Streaming Protocol](./packages/spikes/gulf_client/docs/GenUI_Streaming_Protocol.md)
- [freezed package](https://pub.dev/packages/freezed)
- [State management in Flutter](https://docs.flutter.dev/data-and-backend/state-mgmt/simple)
