# **Flutter Composition Protocol (FCP) Client Implementation Plan**

This document outlines the plan for creating a Flutter package that implements the client-side responsibilities of the Flutter Composition Protocol (FCP).

Package Name: fcp_client
Version: 0.1.0 (Initial)

## **1. Order of Implementation & Milestones**

The implementation will be broken down into logical milestones, building upon each other to progressively deliver the full feature set defined in the FCP specification.

For each milestone, be sure to:

1. Implement all unit tests required to implement the milestone.
2. Run `dart_fix` tool to fix any automatically fixable issues.
3. Run `analyze_files` tool to make sure there are no static errors.
4. Make sure all the tests pass using `run_tests` tool.

### **Milestone 1: Core Models & Static Rendering**

_(Goal: Render a static, non-interactive UI from a complete DynamicUIPacket)_

1. **Project Scaffolding:**
   - Create a new Flutter package (`fcp_client`).
   - Establish directory structure: `/lib`, `/lib/src`, `/lib/src/models`, `/lib/src/widgets`, `/lib/src/core`.
2. **Core Data Models (Serialization):**
   - Implement Dart data models for all JSON structures using **extension types**. This approach avoids build-time code generation and provides type-safe accessors over a raw Map<String, Object?>.
   - WidgetCatalog, WidgetDefinition, PropertyDefinition.
   - DynamicUIPacket, Layout, LayoutNode.
   - EventPayload.
   - StateUpdate (JSON Patch stubs), LayoutUpdate.
3. **Catalog Loading & Parsing:**
   - Create a service to load and parse the WidgetCatalog.json from the app's asset bundle.
4. **Catalog Registry:**
   - Implement a CatalogRegistry class that holds a map of widget type strings (from the catalog) to concrete Flutter FcpWidgetBuilder functions.
   - Initially, this will be populated manually in the example app.
5. **Layout Engine (v1 - Static):**
   - Create an FcpView widget that accepts a DynamicUIPacket.
   - Implement the core "Interpreter" logic that:
     - Parses the Layout's adjacency list (nodes).
     - Builds a map of id to LayoutNode.
     - Recursively constructs the Flutter widget tree starting from the root ID by looking up widget types in the CatalogRegistry.
     - For now, it will only process static properties. bindings will be ignored.

### **Milestone 2: State Management & Data Binding**

_(Goal: Connect the rendered UI to a dynamic state object and support basic data transformations.)_

1. **State Management:**
   - Create a `FcpState` manager (likely using `ChangeNotifier` or another state management solution like Riverpod/Bloc within the `FcpView`).
   - This class will hold the state JSON object from the `DynamicUIPacket`.
2. **Binding Processor:**
   - Develop a `BindingProcessor` service.
   - It will take a `LayoutNode`'s bindings map and the `FcpState` object.
   - Implement logic to resolve a path (e.g., user.name) to a value within the state object.
   - Implement the initial set of transformers: format, condition, and map.
3. **Integrate Bindings into Layout Engine:**
   - Modify the `FcpView` and `CatalogRegistry` to handle bindings.
   - When building a widget, if a property is in bindings, use the BindingProcessor to get its value.
   - Wrap widgets that consume bound data in a state-aware builder (e.g., ValueListenableBuilder if using ChangeNotifier) so they rebuild when the state changes.

### **Milestone 3: Event Handling**

_(Goal: Enable user interactions to be captured and sent to a server.)_

1. **Event Emitter:**
   - The `FcpView` will expose an onEvent callback: `Function(EventPayload)`.
2. **Event Wiring:**
   - Update the `CatalogRegistry`'s builder functions. When a widget definition in the catalog includes an events block (e.g., onPressed), the corresponding Flutter widget must be wired up.
   - For example, a Button's onPressed callback will construct an EventPayload (sourceNodeId, eventName, arguments) and pass it to the FcpView's onEvent callback.

### **Milestone 4: Targeted Updates**

_(Goal: Efficiently patch the UI in response to StateUpdate and LayoutUpdate payloads.)_

1. **State Patcher:**
   - Implement the logic to process StateUpdate payloads.
   - Use a third-party JSON Patch package (e.g., json_patch) to apply the patches array directly to the FcpState object.
   - Applying the patch should automatically trigger the reactive UI to rebuild the affected widgets.
2. **Layout Patcher:**
   - This is more complex. The Layout manager needs methods to handle LayoutUpdate operations:
     - add: Add new LayoutNodes to the internal layout map.
     - remove: Remove LayoutNodes by id.
     - update: Replace existing LayoutNodes.
   - Trigger a targeted rebuild of the UI from the point of the modification. This will require careful state management within the FcpView widget.

### **Milestone 5: Advanced Features & Refinement**

_(Goal: Implement list builders, robust error handling, and formalize data type validation.)_

1. **List View Builder:**
   - Implement a special ListViewBuilder widget in the client's registry.
   - This widget will read its data binding (an array from the state) and use its itemTemplate to build children.
   - It must use Flutter's ListView.builder for performance.
   - The BindingProcessor needs to be enhanced to understand the item. prefix for resolving bindings within the context of a single list item.
2. **Data Type Validation:**
   - Integrate a JSON Schema validator package (e.g., json_schema).
   - During parsing, validate incoming state objects against the schemas defined in dataTypes in the catalog.
3. **Robust Error Handling:**
   - Implement the error handling strategies from Section 7.3.
   - FcpView should show a graceful error widget for:
     - Catalog violations (unknown widget, invalid property).
     - Broken bindings.
     - Payload parsing errors.

## **2\. Testing Plan**

Testing will occur at three levels: unit, widget, and integration.

- **Unit Tests:**
  - **Model Serialization/Deserialization:** Test that all data model classes correctly convert to/from JSON.
  - **Binding Processor:** Test all transformation logic (format, condition, map) with valid and invalid inputs.
  - **State Patcher:** Test StateUpdate logic with all JSON Patch operations.
  - **Layout Patcher:** Test LayoutUpdate logic (add, remove, update).
  - **Catalog Parsing:** Test loading and validation of valid and malformed catalogs.
- **Widget Tests:**
  - **FcpView Rendering:** Test that a valid DynamicUIPacket renders the expected widget tree for various layouts (nested, simple, etc.).
  - **State Binding:** Provide a state object and test that widgets correctly display bound values.
  - **Event Firing:** Test that interacting with a widget (e.g., tapping a button) triggers the onEvent callback with the correct EventPayload.
  - **Error UI:** Test that providing invalid packets or broken bindings results in the display of the designated error widget, not a crash.
  - **ListViewBuilder:** Test that the builder correctly renders a list from a state array and that bindings within the template are resolved correctly.
- **Integration Tests (Example App):**
  - Build a comprehensive example app.
  - Create a mock "server" class that can be controlled by the UI to send various payloads.
  - **Full Flow:** Test the entire sequence: initial load -> event -> state update -> UI rebuild.
  - **Layout Updates:** Test adding, removing, and updating widgets in a live UI.
  - **Complex Scenarios:** Test nested list builders, and multiple data bindings on a single widget.

## **3\. Feature Checklist**

- [x] **Core Models**
  - [x] WidgetCatalog
  - [x] DynamicUIPacket
  - [x] Layout & LayoutNode
  - [x] EventPayload
  - [x] StateUpdate & LayoutUpdate
- [x] **Interpreter**
  - [x] Load & Parse WidgetCatalog
  - [x] CatalogRegistry for mapping types to builders
  - [x] FcpView main widget
  - [x] Static layout rendering from adjacency list
- [x] **State & Bindings**
  - [x] FcpState manager
  - [x] BindingProcessor for path resolution
  - [x] format transformer
  - [x] condition transformer
  - [x] map transformer
  - [x] Reactive widget rebuilding on state change
- [x] **Events**
  - [x] onEvent callback on FcpView
  - [x] Event wiring in widget builders
  - [x] EventPayload construction
- [x] **Live Updates**
  - [x] Apply StateUpdate using JSON Patch
  - [x] Apply LayoutUpdate (add, remove, update)
- [x] **Advanced Features**
  - [x] ListViewBuilder implementation
  - [x] item. context in BindingProcessor
  - [x] JSON Schema validation for dataTypes
- [x] **Error Handling**
  - [x] Fallback UI for parsing errors
  - [x] Fallback UI for catalog violations
  - [x] Default values for broken bindings
- [x] **Documentation**
  - [x] Package README
  - [x] API documentation for all public classes
  - [x] Comprehensive example app
