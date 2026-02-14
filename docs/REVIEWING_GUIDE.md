# GenUI v0.9 Migration & BYO LLM Reviewing Guide

This guide outlines the changes in the `packages/genui` package, focusing on the migration to A2UI Protocol v0.9 and the architectural shift to a "Bring Your Own LLM" model.

## 1. High-Level Architecture Changes

The core change is the decoupling of the AI client implementation from the GenUI framework.

-   **Old Mechanism**: `GenUiConversation` depended on `ContentGenerator` (or `AiClient`), which was responsible for parsing and transport.
-   **New Mechanism**: `Conversation` depends on a `Transport` interface.
    -   **`Transport`**: A simple interface (`incomingText`, `incomingMessages`, `sendRequest`) that you can implement to bridge *any* LLM SDK to GenUI.
    -   **`A2uiTransportAdapter`**: A helper implementation provided for convenience.

## 2. Key Themes

1.  **Protocol v0.9**: Strict adherence to the v0.9 A2UI specification.
    -   Messages are now strongly typed sealed classes (`CreateSurface`, `UpdateComponents`, etc.) in `a2ui_message.dart`.
    -   Validation is built-in.
2.  **"Basic" Catalog**: The "Standard" catalog has been renamed to "Basic" catalog to better reflect its role as a minimal set of fundamental widgets.
3.  **Renames**: Removal of the `GenUi` prefix from most classes to clean up the API (e.g., `GenUiConversation` -> `Conversation`, `GenUiSurface` -> `Surface`).
4.  **Consolidation**: `MultipleChoice`, `CheckboxGroup`, and `RadioGroup` patterns are consolidated into `ChoicePicker`.
5.  **Strict Class Modifiers**: To improve safety and signal intent, we now use specific modifiers:
    *   **`final`**: Applied to data classes (`SurfaceDefinition`, `Component`) and leaf nodes of event hierarchies to prevent extension.
    *   **`sealed`**: Applied to base classes of event hierarchies (`A2uiMessage`, `SurfaceUpdate`, `ConversationEvent`) to enable exhaustive pattern matching.
    *   **`interface`**: Applied to logic/facade classes (`SurfaceController`, `Conversation`, `DataModel`, `Catalog`) to allow mocking (`implements`) while discouraging inheritance (`extends`).

## 3. Deletions (The "Clean Slate")

Several packages and examples have been removed to support the "Bring Your Own LLM" model. The logic previously contained in these provider-specific packages should now be implemented by the user using the `Transport` interface, or via separate provider-specific adapter packages (future work).

### Deleted Packages

*   **`packages/genui_google_generative_ai`**: Removed.
*   **`packages/genui_firebase_ai`**: Removed.
*   **`packages/genui_dartantic`**: Removed.

### Deleted Examples

*   **`examples/simple_chat`**: Removed.

## 4. Recommended Review Order

To make sense of this large PR, I recommend reviewing files in this specific order:

### Phase 1: The New Core Models (The "What")
Start here to understand the data structures driving the system.

1.  **`lib/src/model/a2ui_message.dart`**
    *   **What to look for**: Sealed class hierarchy (`A2uiMessage`, `CreateSurface`, etc.). Note the `v0.9` version check and json parsing logic.
2.  **`lib/src/model/ui_models.dart`**
    *   **What to look for**: `SurfaceDefinition`, `Component` (renamed from `UiComponent`?), and `UiEvent`. These are now `final` classes. `SurfaceUpdate` is `sealed`.
3.  **`lib/src/interfaces/transport.dart`**
    *   **What to look for**: The clean `Transport` interface definition.
4.  **`lib/src/model/generation_events.dart`** (New)
    *   **What to look for**: The `GenerationEvent` sealed class hierarchy (`TextEvent`, `ToolStartEvent`, etc.) used by `Transport`.

### Phase 2: The Facade (The "How User Uses It")
This shows how the changes affect the public API.

5.  **`lib/src/facade/conversation.dart`**
    *   **What to look for**:
        *   Replaces `GenUiConversation`.
        *   Constructor takes `SurfaceController` and `Transport`.
        *   Manages `ConversationState` (reactive state for the UI).
        *   Now an `interface class` to support mocking.
6.  **`lib/src/facade/prompt_builder.dart`** (New)
    *   **What to look for**: Helper for constructing usage prompts (system instructions) separate from the conversation logic.
7.  **`lib/src/model/basic_catalog_embed.dart`** (New)
    *   **What to look for**: Static container for basic catalog rules, used by `PromptBuilder` to inject catalog instructions without file I/O.

### Phase 3: The Engine (The "Brain")
This is where the logic lives.

6.  **`lib/src/engine/surface_controller.dart`**
    *   **What to look for**:
        *   Replaces `GenUiController` / `A2uiMessageProcessor`.
        *   `handleMessage`: routing logic for A2UI messages.
        *   `_registry` and `_store` management.
        *   Now an `interface class`.
7.  **`lib/src/engine/surface_registry.dart`**
    *   **What to look for**: How surfaces are tracked and looked up.
8.  **`lib/src/engine/data_model_store.dart`**
    *   **What to look for**: Centralized management of data models for multiple surfaces.
9.  **`lib/src/engine/cleanup_strategy.dart`** (New)
    *   **What to look for**: Policy for cleaning up old surfaces (e.g., `MaxSurfacesCleanupStrategy`).

### Phase 4: Use & Rendering (The "Visuals")
9.  **`lib/src/widgets/surface.dart`**
    *   **What to look for**: Replaces `GenUiSurface`. Renders the `SurfaceDefinition` from the registry.
10. **`lib/src/catalog/basic_catalog.dart`**
    *   **What to look for**: The rename from `core_catalog.dart`.
    *   **Note**: Check `lib/src/catalog/basic_catalog_widgets/choice_picker.dart` to see the new consolidated selection component.
    *   `BasicCatalogItems` is now an `abstract final class` (static namespace).

### Phase 5: Transport Implementation (The "Plumbing")
11. **`lib/src/transport/a2ui_parser_transformer.dart`**
    *   **What to look for**: Logic for splitting stream chunks and parsing JSON objects (handling split JSONs).
12. **`lib/src/transport/a2ui_transport_adapter.dart`**
    *   **What to look for**: The "glue" class that makes it easy to use standard stream-based LLM SDKs.

## 5. Renames Cheat Sheet

| Old Name | New Name | Notes |
| :--- | :--- | :--- |
| `GenUiConversation` | `Conversation` | Public Facade |
| `GenUiController` | `SurfaceController` | Engine |
| `GenUiSurface` | `Surface` | Widget |
| `GenUiContext` | `SurfaceContext` | Interface |
| `UiDefinition` | `SurfaceDefinition` | Model |
| `StandardCatalog` | `BasicCatalog` | Catalog |
| `MultipleChoice` | `ChoicePicker` | Component |
| `ContentGenerator` | `Transport` | *Conceptually replaced* |
| `AiClient` | `Transport` | *Conceptually replaced* |

## 6. Deleted/Obsolete Files (Internal to `genui`)
These files have been removed internal to `genui`. Verify that their functionality is truly covered by the new architecture.

*   `content_generator.dart` -> Replaced by `Transport`.
*   `genui_surface.dart` -> Replaced by `surface.dart`.
*   `ui_tools.dart` -> Function calling logic moved to `functions/`.

## 7. File-by-File Changes (Detailed Review)

### `lib/` (Root)

*   **`genui.dart`** (Modified):
    *   **Change**: Complete overhaul of exports. Removed `GenUiConversation`, `GenUiController` exports. Added `Conversation`, `SurfaceController`, `Transport`, `PromptBuilder`.
    *   **Context**: Public API surface has changed entirely to support the new architecture. `A2uiParserTransformer` and `A2uiTransportAdapter` are also exported here for convenience.
*   **`parsing.dart`** (New):
    *   **Change**: Added new library for parsing utilities. Exports `JsonBlockParser`.
    *   **Context**: Focused on low-level parsing strategies.

### `lib/src/catalog` (Renamed & Refactored)

*   **`basic_catalog.dart`** (Renamed from `core_catalog.dart`):
    *   **Change**: Renamed class `StandardCatalog` -> `BasicCatalog` and `StandardCatalogItems` -> `BasicCatalogItems`.
    *   **Context**: "Basic" better reflects the minimalist nature of this widget set.
*   **`basic_catalog_widgets/choice_picker.dart`** (New):
    *   **Change**: Introduces `ChoicePicker` component.
    *   **Context**: Replaces and consolidates `multiple_choice.dart`, `check_box_group.dart`, etc. Unifies selection logic.
*   **`basic_catalog_widgets`** (Moved):
    *   Moved from `core_widgets`. Most files are simple moves, but some (like `check_box.dart`) have been modified to map to the new `BasicCatalog` structure.

### `lib/src/engine` (The New Core)

*   **`surface_controller.dart`** (New):
    *   **Change**: Implements the main A2UI message processing loop. Handles `CreateSurface`, `UpdateComponents`, `UpdateDataModel`, `DeleteSurface`.
    *   **Context**: Replaces `GenUiController` and `A2uiMessageProcessor`.
*   **`surface_registry.dart`** (New):
    *   **Change**: Manages active surfaces (`SurfaceDefinition` storage).
    *   **Context**: Decoupled from the controller to allow easier lookup.
*   **`data_model_store.dart`** (New):
    *   **Change**: Manages data models (variables) for surfaces.
    *   **Context**: Centralized state management for the "UpdateDataModel" messages.
*   **`cleanup_strategy.dart`** (New):
    *   **Change**: Defines surface cleanup policies (e.g., how many surfaces to keep in memory).

*   **Deletions in `lib/src/core/`**:
    *   `a2ui_message_processor.dart`: Logic moved to `SurfaceController`.
    *   `genui_surface.dart`: Replaced by `lib/src/widgets/surface.dart`.
    *   `prompt_fragments.dart`: Moved/Refactored into `PromptBuilder`.
    *   `ui_tools.dart`: Function calling logic moved to `lib/src/functions/`.
    *   `widget_utilities.dart`: Moved to `lib/src/widgets/`.

### `lib/src/facade` (Public API)

*   **`conversation.dart`** (New):
    *   **Change**: High-level orchestrator. Connects `Transport` to `SurfaceController`.
    *   **Context**: Replaces `GenUiConversation`.
*   **`prompt_builder.dart`** (New):
    *   **Change**: Helper to build the system prompt with A2UI instructions.
    *   **Context**: Decouples prompt logic from the conversation class.

*   **Deletions**:
    *   `gen_ui_conversation.dart`: Replaced by `conversation.dart`.
    *   `direct_call_integration/`: **Entire directory deleted**. The direct call integration mechanism is being replaced by standard tool calling.

### `lib/src/functions` (New)

*   **`functions.dart`**, **`expression_parser.dart`** (New):
    *   **Change**: Implements client-side expression evaluation and function definitions for A2UI client-side logic.
    *   **Context**: Replaces the logic previously in `ui_tools.dart`.

### `lib/src/interfaces` (New Contracts)

*   **`transport.dart`** (New):
    *   **Change**: Defines the `Transport` interface (`incomingMessages`, `sendRequest`).
    *   **Context**: The core abstraction for "Bring Your Own LLM".
*   **`surface_host.dart`**, **`surface_context.dart`** (New):
    *   **Change**: Interfaces for widgets to interact with the engine.
    *   **Context**: Decouples the widget tree from the controller implementation.

### `lib/src/model` (Data Structures)

*   **`a2ui_message.dart`** (Modified):
    *   **Change**: Converted to `sealed class` hierarchy for v0.9 (strict types).
    *   **Details**:
        *   `SurfaceUpdate` -> Renamed to `UpdateComponents`.
        *   `DataModelUpdate` -> Renamed to `UpdateDataModel`.
        *   `BeginRendering` -> Renamed to `CreateSurface`.
        *   `SurfaceDeletion` -> Renamed to `DeleteSurface`.
        *   All messages now include `version: 'v0.9'`.
    *   **Context**: The "source of truth" for the protocol.
*   **`ui_models.dart`** (Modified):
    *   **Change**: `Component` structure flattened in JSON.
    *   **Details**: The `component` property (which contained the properties map) is gone. Now, properties are top-level keys relative to the component object (minus `id` and `type`).
    *   **Validation**: Extensive schema validation added to `SurfaceDefinition`.
    *   **Event Bus**: added `SurfaceUpdate` sealed classes (`SurfaceAdded`, `ComponentsUpdated`, `SurfaceRemoved`) for internal event handling.
*   **`generation_events.dart`** (New):
    *   **Change**: Defines the event hierarchy (`ThinkingEvent`, `ToolStartEvent`, `A2uiMessageEvent`) emitted by the `Transport`.
*   **`basic_catalog_embed.dart`** (New):
    *   **Change**: Embeds the basic catalog rules as a const string.
    *   **Context**: Simplifies `PromptBuilder` usage.
*   **`parts/ui.dart`** (Modified):
    *   **Change**: `UiPart` and `UiInteractionPart` no longer extend `Part`.
    *   **Details**: They are now wrapper classes (views) around `DataPart` that use specific MIME types (`application/vnd.genui.ui+json`). This aligns with the `genai_primitives` standard.
*   **`data_model.dart`** (Modified):
    *   **Change**: Updates to observing data changes.
*   **`parts/image.dart`** (Deleted):
    *   **Change**: Image part handling is likely covered by generic `DataPart` or moved.

### `lib/src/transport` (Default Implementation)

*   **`a2ui_transport_adapter.dart`** (New):
    *   **Change**: Adapts a generic `Stream<String>` (from any LLM) into a `Transport`.
    *   **Context**: The bridge for users migrating from the old `ContentGenerator`.
*   **`a2ui_parser_transformer.dart`** (New):
    *   **Change**: Stream transformer that parses partial JSON chunks.
    *   **Context**: Critical for handling streaming LLM output robustly.

*   **Deletions**:
    *   `content_generator.dart`: Replaced by `Transport`.

### `lib/src/widgets` (Rendering)

*   **`surface.dart`** (New):
    *   **Change**: The main widget that renders a UI surface.
    *   **Context**: Replaces `GenUiSurface`.
*   **`fallback_widget.dart`** (New):
    *   **Change**: Displayed when a component type is unknown or fails to render.
*   **`widget_utilities.dart`** (New):
    *   **Change**: Introduced `OptionalValueBuilder` and `DataContext` extension methods (`subscribeToString`, etc.) that handle type coercion resiliently.
    *   **Context**: Moved/Refactored from `src/core/`.

### `packages/genui_a2ui` (Adapter Package)
This package has been updated to use the new `genui` core.

*   **`lib/src/a2ui_agent_connector.dart`** (Modified):
    *   **Change**: deeply updated to use `genui` v0.9 models (`A2uiMessage`, `ChatMessage` parts).
    *   **Context**: Connects to an existing A2UI Agent (using `a2a` client) and streams responses.
*   **`lib/src/a2ui_content_generator.dart`** (Deleted):
    *   **Change**: Removed.
    *   **Context**: The concept of `ContentGenerator` is replaced by `Transport`, but `A2uiAgentConnector` serves as the primary entry point for this package now.
*   **`lib/src/logging_utils.dart`** (New):
    *   **Change**: Added log sanitization helpers.


## New Layout

```
<package root>
├── docs
│   └── assets
├── examples
│   ├── catalog_gallery
│   │   ├── build
│   │   │   ├── native_assets
│   │   │   │   └── flutter-tester
│   │   │   ├── test_cache
│   │   │   │   └── build
│   │   │   └── unit_test_assets
│   │   │       ├── fonts
│   │   │       └── shaders
│   │   ├── integration_test
│   │   ├── lib
│   │   ├── samples
│   │   └── test
│   │       └── src
│   ├── simple_chat
│   │   ├── build
│   │   │   ├── native_assets
│   │   │   │   └── flutter-tester
│   │   │   ├── test_cache
│   │   │   │   └── build
│   │   │   └── unit_test_assets
│   │   │       ├── fonts
│   │   │       └── shaders
│   │   ├── integration_test
│   │   │   └── samples
│   │   ├── lib
│   │   │   └── api_key
│   │   └── test
│   ├── travel_app
│   │   ├── assets
│   │   │   ├── booking_service
│   │   │   ├── prompt_images
│   │   │   └── travel_images
│   │   ├── build
│   │   │   ├── native_assets
│   │   │   │   └── flutter-tester
│   │   │   ├── test_cache
│   │   │   │   └── build
│   │   │   └── unit_test_assets
│   │   │       ├── assets
│   │   │       │   ├── booking_service
│   │   │       │   └── travel_images
│   │   │       ├── fonts
│   │   │       ├── packages
│   │   │       │   ├── flutter_math_fork
│   │   │       │   │   └── lib
│   │   │       │   │       └── katex_fonts
│   │   │       │   │           └── fonts
│   │   │       │   └── gpt_markdown
│   │   │       │       └── lib
│   │   │       │           └── fonts
│   │   │       └── shaders
│   │   ├── integration_test
│   │   ├── lib
│   │   │   └── src
│   │   │       ├── ai_client
│   │   │       ├── catalog
│   │   │       ├── config
│   │   │       ├── tools
│   │   │       │   └── booking
│   │   │       └── widgets
│   │   └── test
│   │       ├── ai_client
│   │       ├── goldens
│   │       ├── tools
│   │       │   └── hotels
│   │       └── widgets
│   └── verdure
│       ├── client
│       │   ├── assets
│       │   │   ├── fonts
│       │   │   └── images
│       │   └── lib
│       │       ├── core
│       │       │   └── theme
│       │       └── features
│       │           ├── ai
│       │           ├── screens
│       │           ├── state
│       │           └── widgets
│       └── server
│           ├── a2ui_extension
│           │   └── src
│           │       └── a2ui_ext
│           └── verdure
│               └── images
├── packages
│   ├── genai_primitives
│   │   ├── example
│   │   ├── lib
│   │   │   └── src
│   │   │       └── parts
│   │   └── test
│   ├── genui
│   │   ├── build
│   │   │   ├── native_assets
│   │   │   │   └── flutter-tester
│   │   │   ├── test_cache
│   │   │   │   └── build
│   │   │   └── unit_test_assets
│   │   │       └── shaders
│   │   ├── example
│   │   ├── lib
│   │   │   ├── src
│   │   │   │   ├── catalog
│   │   │   │   │   └── basic_catalog_widgets
│   │   │   │   ├── development_utilities
│   │   │   │   ├── engine
│   │   │   │   ├── facade
│   │   │   │   │   └── widgets
│   │   │   │   ├── functions
│   │   │   │   ├── interfaces
│   │   │   │   ├── model
│   │   │   │   │   └── parts
│   │   │   │   ├── primitives
│   │   │   │   ├── transport
│   │   │   │   ├── utils
│   │   │   │   └── widgets
│   │   │   └── test
│   │   └── test
│   │       ├── catalog
│   │       │   └── core_widgets
│   │       ├── core
│   │       ├── development_utilities
│   │       ├── engine
│   │       ├── facade
│   │       ├── functions
│   │       ├── model
│   │       ├── transport
│   │       └── utils
│   ├── genui_a2ui
│   │   ├── build
│   │   │   ├── native_assets
│   │   │   │   └── flutter-tester
│   │   │   ├── test_cache
│   │   │   │   └── build
│   │   │   └── unit_test_assets
│   │   │       ├── fonts
│   │   │       └── shaders
│   │   ├── lib
│   │   │   └── src
│   │   │       └── a2a
│   │   │           ├── client
│   │   │           └── core
│   │   └── test
│   │       └── a2a
│   │           ├── client
│   │           └── core
│   └── json_schema_builder
│       ├── bin
│       ├── example
│       ├── lib
│       │   └── src
│       │       └── schema
│       └── test
└── specs
```