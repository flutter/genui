# `genui` Package Context for AI Agents

## Purpose

This document provides context for AI agents working with the `genui` package. This package is the core framework for building generative user interfaces in Flutter, where the UI is dynamically constructed by an AI model in real-time.

## Key Concepts

- **`GenUiConversation`**: The main facade and entry point. It manages the conversation loop, orchestrates the `GenUiManager` and `ContentGenerator`, and handles the flow of messages.
- **`ContentGenerator`**: An abstract interface for communicating with AI models. Concrete implementations (like `FirebaseAiContentGenerator` in `genui_firebase_ai`) handle specific model APIs.
- **`GenUiManager`**: Manages the state of the dynamic UI, including active surfaces and the `DataModel`.
- **`Catalog`**: A registry of `CatalogItem`s (widgets) that the AI can use. Each item has a schema and a builder.
- **`DataModel`**: A centralized, observable store for UI state. Widgets are bound to paths in this model and update reactively.
- **`A2uiMessage`**: The protocol for AI commands to the UI (e.g., `SurfaceUpdate`, `BeginRendering`).

## Architecture

See [DESIGN.md](./DESIGN.md) for a detailed architectural overview.

The package is layered:

1.  **Content Generator Layer**: `lib/src/content_generator.dart` (AI communication).
2.  **UI State Management Layer**: `lib/src/core/` (`GenUiManager`, `ui_tools.dart`).
3.  **UI Model Layer**: `lib/src/model/` (Data structures like `A2uiMessage`, `UiDefinition`, `DataModel`).
4.  **Widget Catalog Layer**: `lib/src/catalog/` (Core widgets like `Text`, `Button`, `Column`).
5.  **UI Facade Layer**: `lib/src/conversation/` (`GenUiConversation`, `GenUiSurface`).

## Usage

See [README.md](./README.md) for getting started guides and examples.

Typical usage involves:

1.  Initializing a `GenUiManager` with a `Catalog`.
2.  Initializing a `ContentGenerator` (e.g., `FirebaseAiContentGenerator`).
3.  Creating a `GenUiConversation` with the manager and generator.
4.  Sending user prompts via `genUiConversation.sendRequest()`.
5.  Rendering `GenUiSurface` widgets based on surface IDs from `onSurfaceAdded` callbacks.

## File Structure

- `lib/genui.dart`: Main export file.
- `lib/src/catalog/`: Core widget implementations (`core_catalog.dart`, `core_widgets/`).
- `lib/src/content_generator.dart`: `ContentGenerator` interface.
- `lib/src/conversation/`: `GenUiConversation` and `GenUiSurface`.
- `lib/src/core/`: `GenUiManager`, `GenUiConfiguration`, `ui_tools.dart`.
- `lib/src/model/`: Data models (`a2ui_message.dart`, `data_model.dart`, `catalog.dart`).
