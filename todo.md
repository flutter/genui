# GenUI Migration Todo List

This document outlines the steps required to migrate the `flutter_genui` package from a direct-response architecture to a more flexible tool-based architecture, as detailed in `migration.md`.

## Phase 1: Core `flutter_genui` Package Refactoring

The goal of this phase is to refactor the core package to support the new, decoupled architecture.

- [x] **Modify `AiClient` Interface (`lib/src/ai_client/ai_client.dart`)**

  - [x] Add a new `generateText` method for simple text generation that still can do optional tool calling.

- [x] **Implement UI Generation Tools (`lib/src/ai_client/ui_tools.dart`)**

  - [x] Create the new file `lib/src/ai_client/ui_tools.dart`.
  - [x] Implement `AddOrUpdateSurfaceTool`, which takes a `GenUiManager` in its constructor.
  - [x] Implement `DeleteSurfaceTool`, which takes a `GenUiManager` in its constructor.

- [x] **Refactor `GenUiManager` (`lib/src/core/genui_manager.dart`)**

  - [x] Replace the implementation of the old `GenUiManager` with the logic from `NewGenUiManager`.
  - [x] Remove any reference to `AiClient` and methods related to making inference calls (e.g., `sendUserPrompt`).
  - [x] Implement the internal state management using `Map<String, ValueNotifier<UiDefinition?>>`.
  - [x] Implement the public `getTools()` method to return the UI generation tools.
  - [x] Implement the public `addOrUpdateSurface(surfaceId, definition)` method.
  - [x] Implement the public `deleteSurface(surfaceId)` method.
  - [x] Define the `GenUiUpdate` sealed class and its subtypes (`SurfaceAdded`, `SurfaceUpdated`, `SurfaceRemoved`).
  - [x] Implement the public `Stream<GenUiUpdate> get updates` stream and emit events from the `add/update/delete` methods.

- [x] **Update `SurfaceWidget` (`lib/src/model/surface_widget.dart`)**

  - [x] Refactor the constructor to accept `GenUiManager manager`, `String surfaceId`, and `UiEventCallback onEvent`.
  - [x] Implement the logic to listen to the correct `ValueNotifier` within the `GenUiManager` based on the `surfaceId`.
  - [x] Ensure the widget rebuilds when the `ValueNotifier` emits a new `UiDefinition`.
  - [x] Implement the event forwarding mechanism to call the `onEvent` callback when a UI event is dispatched from a catalog widget.

- [x] **Update `FakeAiClient` (`pkgs/flutter_genui/lib/test/fake_ai_client.dart`)**

  - [x] Update the method signatures to match the new `AiClient` interface, adding `generateText`.
  - [x] Add logic to simulate tool invocation, allowing tests to provide a handler that can inspect the conversation and return mock tool calls.
  - [x] Add logic to simulate tool invocation, allowing tests to provide a handler that can inspect the conversation and return mock tool calls.

- [x] **Update `GenUiManager` Tests (`pkgs/flutter_genui/test/core/genui_manager_test.dart`)**

  - [x] Rewrite tests to verify the manager's new responsibilities as a pure state container.
  - [x] Test that `addOrUpdateSurface` correctly updates the internal state and fires a `SurfaceAdded` or `SurfaceUpdated` event.
  - [x] Test that `deleteSurface` correctly updates the internal state and fires a `SurfaceRemoved` event.
  - [x] Test that `getTools()` returns the correctly configured UI tools.

- [x] **Phase 1 Quality Check & Checkpoint**
  - [x] Run `dart fix --apply` across the `pkgs/flutter_genui` package.
  - [x] Run `dart format .` across the `pkgs/flutter_genui` package.
  - [x] Run `flutter analyze` on the `pkgs/flutter_genui` package and ensure there are no errors.
  - [x] Run all tests within the `pkgs/flutter_genui` package.
  - [x] Create a git commit with the message: `feat: [GenUI] Phase 1 - Refactor core package to support tool-based architecture`.

## Phase 2: Example Migration

The goal of this phase is to update the example applications to use the new, decoupled API.

- [x] **Update `minimal_genui` Example (`examples/minimal_genui/lib/main.dart`)**

  - [x] Refactor the main widget to be a `StatefulWidget`.
  - [x] Instantiate `GenUiManager`.
  - [x] Instantiate `GeminiAiClient`, passing the tools from `genUiManager.getTools()`.
  - [x] Implement conversation history management (`List<ChatMessage>`).
  - [x] Implement an `_handleUiEvent` method to process events from the `SurfaceWidget`.
  - [x] Implement a `_sendPrompt` method to add user text to the history and trigger an inference.
  - [x] Subscribe to the `genUiManager.updates` stream to manage a list of active `surfaceIds`.
  - [x] Update the `build` method to render a `ListView` of `SurfaceWidget`s based on the active `surfaceIds`.
  - [x] Update the system prompt for the `GeminiAiClient` to instruct the LLM to use the new tools.

- [x] **Update `travel_app` Example (`examples/travel_app/lib/main.dart`)**

  - [x] Apply the same set of refactoring changes as in the `minimal_genui` example.

- [x] **Phase 2 Quality Check & Checkpoint**
  - [x] Run `dart fix --apply` across the `examples` directory.
  - [x] Run `dart format .` across the `examples` directory.
  - [x] Run `flutter analyze` on the `examples` directory and ensure there are no errors.
  - [ ] Manually run both the `minimal_genui` and `travel_app` examples to ensure they are functional.
  - [x] Create a git commit with the message: `feat: [GenUI] Phase 2 - Migrate examples to new tool-based architecture`.

## Phase 3: Test Migration

The goal of this phase is to update all tests to be compatible with the new architecture and ensure the project is stable.

- [ ] **Update `travel_app` Widget Tests (`examples/travel_app/test/`)**

  - [ ] Refactor all widget tests to use the new `GenUiManager` and `FakeAiClient`.
  - [ ] Instead of building widgets with static `UiDefinition`s, tests should now simulate the full flow: trigger an event, have the `FakeAiClient` "call" a UI tool, and verify that the `SurfaceWidget` updates correctly.

- [ ] **Phase 3 Quality Check & Checkpoint**
  - [ ] Run `dart fix --apply` across the entire project.
  - [ ] Run `dart format .` across the entire project.
  - [ ] Run `flutter analyze` across the entire project and ensure there are no errors.
  - [ ] Run all tests across the entire project and ensure they all pass.
  - [ ] Create a git commit with the message: `feat: [GenUI] Phase 3 - Migrate all tests to new tool-based architecture`.
