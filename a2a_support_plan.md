# A2UI Protocol Adoption Plan

This document outlines the implementation plan to refactor the `flutter_genui` SDK to natively support the A2UI (Generative UI Language Format) protocol. The goal is to replace the current proprietary tool-based UI manipulation with a standards-compliant message-passing system, making the SDK more robust, flexible, and interoperable.

## Testing and Validation Strategy

Throughout this refactoring process, we will maintain code quality and catch regressions early by frequently running the comprehensive check script.

**After any significant file modification, and especially at each checkpoint, run the following command from the repository root:**

```bash
./tool/run_all_tests_and_fixes.sh
```

This script handles formatting, applying automatic fixes, running all unit tests, and performing static analysis for all packages in the monorepo. Adhering to this practice is critical for a smooth and error-free implementation.

## Phase 1: Core Data Models and `GenUiManager` Refactoring

This phase focuses on building the foundational data structures for A2UI and refactoring the core state manager (`GenUiManager`) to use them. At the end of this phase, the internal logic will be A2UI-compliant, but the public-facing tools will be broken.

### Step 1.1: Create A2UI Data Classes

We will create a set of immutable Dart classes to represent the A2UI message structure. These will be located in a new file: `packages/flutter_genui/lib/src/model/a2ui_message.dart`.

-   **`A2uiMessage`**: A sealed class (or a class with a `fromJson` factory that delegates to subtypes) that represents any message in the A2UI stream. It will have a `fromJson` factory to parse incoming JSON.
-   **`SurfaceUpdate`**: Represents the `surfaceUpdate` message, containing a `List<Component>`.
-   **`DataModelUpdate`**: Represents the `dataModelUpdate` message, containing `contents` and an optional `path`.
-   **`BeginRendering`**: Represents the `beginRendering` message, containing the `root` component ID and, eventually, `catalogUri` and `styles`.
-   **`SurfaceDeletion`**: Represents the `surfaceDeletion` message.
-   **`Component`**: A class representing a single component with an `id` and `componentProperties` (a `JsonMap`).

These classes will be pure data holders, ensuring a clean separation of data and logic.

### Step 1.2: Refactor `UiDefinition`

The existing `UiDefinition` extension type will be converted into a standalone class. This class will represent the complete state of a single UI surface.

-   **File**: `packages/flutter_genui/lib/src/model/ui_models.dart`
-   **Structure**:
    -   `String surfaceId`
    -   `String rootComponentId`
    -   `Map<String, Component> components`: A map of all component instances for this surface, keyed by their ID.
    -   (Future) `Uri catalogUri`
    -   (Future) `JsonMap styles`

This change decouples the surface state from a raw `JsonMap`, providing a more structured and type-safe way to manage the UI.

### Step 1.3: Refactor `GenUiManager`

The `GenUiManager` will be significantly overhauled to become a message processor.

-   **Remove Methods**: The public methods `addOrUpdateSurface(String surfaceId, JsonMap definition)` and `deleteSurface(String surfaceId)` will be removed.
-   **Add New Method**: A new central method will be introduced: `void handleMessage(A2uiMessage message)`.
-   **Internal State**: The `_surfaces` map will be changed from `Map<String, ValueNotifier<UiDefinition?>>` to `Map<String, ValueNotifier<UiDefinition?>>`, where the new `UiDefinition` class is used.
-   **Message Handling Logic**: The `handleMessage` method will act as a dispatcher.
    -   On `SurfaceUpdate`: It will find the corresponding `UiDefinition` for the `surfaceId`. It will then iterate through the `components` in the message and add or update them in the `UiDefinition`'s `components` map. After updating, it will perform a garbage collection pass, removing any components that are no longer referenced in the component tree, starting from the root.
    -   On `DataModelUpdate`: This will be implemented in a later phase. For now, the message can be ignored.
    -   On `BeginRendering`: It will update the `rootComponentId` in the appropriate `UiDefinition`.
    -   On `SurfaceDeletion`: It will remove the surface from the `_surfaces` map.
-   **Updates**: After processing a message, `GenUiManager` will notify listeners via the `surfaceUpdates` stream as usual.

**After completing the `GenUiManager` refactoring, run the validation script:** `./tool/run_all_tests_and_fixes.sh`. Many tests will be broken, but this ensures the modified files are correctly formatted and analyzed.

### Checkpoint 1

-   **Goal**: The core data models for A2UI are implemented, and `GenUiManager` can process these messages to manage UI state internally.
-   **State of the Code**: The SDK will be in a broken state. The `getTools()` method will still return the old tools, which no longer have corresponding methods to call on `GenUiManager`. Sample apps and tests will fail to compile.
-   **Validation**: Run `./tool/run_all_tests_and_fixes.sh`. Expect test failures, but fix any analysis or formatting errors.
-   **Commit Message**: `feat(a2ui): Refactor GenUiManager and introduce core A2UI data models`

## Phase 2: Adapting Existing Tools and Restoring Functionality

This phase focuses on bridging the gap between the AI's current tool-calling output and the new message-based system. We will make the SDK functional again by adapting the existing tools to be a compatibility layer.

### Step 2.1: Adapt `AddOrUpdateSurfaceTool`

-   **File**: `packages/flutter_genui/lib/src/core/ui_tools.dart`
-   **Schema**: The `parameters` schema will remain largely the same to ensure backward compatibility for the LLM.
-   **Implementation**:
    -   The constructor will be updated to accept a `handleMessage` callback (`void Function(A2uiMessage message)`).
    -   The `invoke` method will be rewritten. It will take the existing `definition` (`{'root': '...', 'widgets': [...]}`) and convert it into a sequence of A2UI messages.
    1.  It will first create a `SurfaceUpdate` message. The `widgets` list from the old format will be transformed into a list of `Component` objects (where the old `widget` property becomes `componentProperties`).
    2.  It will then create a `BeginRendering` message, using the `root` ID from the old definition.
    3.  It will call `handleMessage` for each of these messages in order.

### Step 2.2: Adapt `DeleteSurfaceTool`

-   **File**: `packages/flutter_genui/lib/src/core/ui_tools.dart`
-   **Implementation**:
    -   The constructor will be updated to accept the `handleMessage` callback.
    -   The `invoke` method will be rewritten to create a single `SurfaceDeletion` message using the provided `surfaceId` and pass it to `handleMessage`.

### Step 2.3: Create `A2UiTool` (for future use)

A new, primary tool will be created for future direct A2UI manipulation, but it **will not be used yet**.

-   **New File**: `packages/flutter_genui/lib/src/core/a2ui_tool.dart`
-   **Class**: `A2UiTool`
-   **Schema**: The tool's `parameters` schema will be a direct representation of the A2UI protocol schema (`protocol_schema.json`).
-   **Implementation**: The `invoke` method will parse the incoming `JsonMap` into an `A2uiMessage` and pass it to a `handleMessage` callback.
-   **Integration**: This tool **will not** be added to `GenUiManager.getTools()` at this stage. It is being created now to complete the API surface but will be integrated in a later step.

### Step 2.4: Update `GenUiManager.getTools()`

The `getTools()` method in `GenUiManager` will be updated to instantiate the adapted `AddOrUpdateSurfaceTool` and `DeleteSurfaceTool`, passing its `handleMessage` method as the callback.

### Checkpoint 2

-   **Goal**: The SDK is fully functional again. The existing tools now act as a compatibility layer, converting the old format into A2UI messages for the refactored `GenUiManager`.
-   **Test/App Updates**:
    -   **Unit Tests**: All unit tests for `GenUiManager` and the tools must be rewritten. New tests will verify the conversion logic in the tools and the state changes in `GenUiManager`.
    -   **Sample Apps (`simple_chat`, `travel_app`)**: The apps should now work without significant changes, as the tool interface they rely on has been preserved.
-   **Validation**: Run `./tool/run_all_tests_and_fixes.sh`. All tests should now pass.
-   **Commit Message**: `feat(a2ui): Adapt existing tools to support A2UI message passing`

## Phase 3: Supporting Catalog Negotiation and Full `BeginRendering`

**Note:** This phase outlines future work and should not be implemented until explicitly requested. The goal of the current task is to complete Phases 1 and 2.

This final phase implements the more advanced features of the A2UI protocol, enabling true platform-agnostic UI generation and dynamic styling.

### Step 3.1: Enhance `Catalog` and `GenUiManager`

-   **`Catalog`**: Add a `Uri uri` property to the `Catalog` class to give each catalog a unique identifier.
-   **`GenUiManager` Constructor**: Modify the constructor to accept a `List<Catalog>` instead of a single `Catalog`.
-   **`GenUiManager.uiCapabilities`**: Add a new getter: `String get uiCapabilities`. This will generate a `clientUiCapabilities` JSON message as a string. The message will contain the URIs of all catalogs provided to the manager. This string can be sent to the server/LLM to inform it of the client's rendering capabilities.
-   **State Management**: `GenUiManager` will be updated to store the `catalogUri` received in a `BeginRendering` message, associating it with the corresponding `surfaceId`.

### Step 3.2: Update Rendering Logic

The UI rendering logic (primarily within the `GenUiSurface` widget) will be updated to support multiple catalogs.

-   When a `GenUiSurface` for a specific `surfaceId` builds its widget tree, it will first look up which catalog is associated with that surface in `GenUiManager`.
-   It will then use the correct `Catalog` instance to build the widgets, ensuring that the components generated by the AI are rendered using the intended component set.

### Checkpoint 3

-   **Goal**: The SDK fully supports the A2UI specification, including catalog negotiation. The client can now advertise its capabilities and render UI from different, dynamically-selected component sets.
-   **Test/App Updates**:
    -   Add unit tests for the `uiCapabilities` getter in `GenUiManager`.
    -   Add tests to verify that `GenUiManager` correctly associates a catalog with a surface upon receiving a `BeginRendering` message.
    -   Create a new example app or modify an existing one to demonstrate the use of multiple catalogs, showcasing the dynamic capabilities of the system.
-   **Validation**: Run `./tool/run_all_tests_and_fixes.sh`. All tests should continue to pass.
-   **Commit Message**: `feat(a2ui): Implement catalog negotiation and full BeginRendering support`
