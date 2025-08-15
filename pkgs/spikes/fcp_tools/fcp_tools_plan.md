# FCP Tools Package Implementation Plan

This document outlines the detailed plan to create the `fcp_tools` package as specified in `fcp_tools.md`.

## 1. Goals

-   Create a robust and reusable package for conversational UI generation.
-   Implement the `FcpSurfaceManager` to handle the lifecycle of UI surfaces.
-   Implement the `manage_ui` and `get_widget_catalog` AI tools.
-   Provide a comprehensive example application demonstrating the package's capabilities.

## 2. Package Structure

The new package will be created at `pkgs/spikes/fcp_tools` with the following structure:

```
pkgs/spikes/fcp_tools/
├── lib/
│   ├── src/
│   │   ├── fcp_surface_manager.dart
│   │   └── tools/
│   │       ├── manage_ui.dart
│   │       └── get_widget_catalog.dart
│   ├── fcp_tools.dart (exports)
│   └── test.dart (exports test utilities)
├── test/
│   ├── fcp_surface_manager_test.dart
│   └── tools/
│       ├── manage_ui_test.dart
│       └── get_widget_catalog_test.dart
├── example/
│   ├── lib/
│   │   └── main.dart
│   └── ... (standard Flutter app structure)
├── analysis_options.yaml
├── CHANGELOG.md
├── LICENSE
├── pubspec.yaml
└── README.md
```

## 3. Detailed Checklist

### Phase 1: Package Scaffolding

-   [x] Create the root directory: `pkgs/spikes/fcp_tools`.
-   [x] Create the `lib`, `lib/src`, `lib/src/tools`, `test`, `test/tools`, and `example` directories.
-   [x] Create a `pubspec.yaml` file with the necessary dependencies.
-   [x] Create a standard `analysis_options.yaml` file.
-   [x] Add `README.md`, `CHANGELOG.md`, and `LICENSE` files.

### Phase 2: Core Implementation

-   [x] **`FcpSurfaceManager`:**
    -   [x] Create `pkgs/spikes/fcp_tools/lib/src/fcp_surface_manager.dart`.
    -   [x] Implement the `FcpSurfaceManager` class to manage a map of `surfaceId` to `FcpViewController`.
    -   [x] Implement the `createSurface`, `getSurface`, `listSurfaces`, and `removeSurface` methods.
-   [x] **`manage_ui` Tool:**
    -   [x] Create `pkgs/spikes/fcp_tools/lib/src/tools/manage_ui.dart`.
    -   [x] Implement the `ManageUiTool` class, which will be a collection of `DynamicAiTool`s for each action (`set`, `get`, `list`, `remove`, `patchLayout`, `patchState`).
    -   [x] The tool will take an `FcpSurfaceManager` as a dependency.
-   [x] **`get_widget_catalog` Tool:**
    -   [x] Create `pkgs/spikes/fcp_tools/lib/src/tools/get_widget_catalog.dart`.
    -   [x] Implement the `GetWidgetCatalogTool` class as a `DynamicAiTool`.
    -   [x] The tool will take a `WidgetCatalog` as a dependency.
-   [x] **Public API:**
    -   [x] Create `pkgs/spikes/fcp_tools/lib/fcp_tools.dart` to export the necessary classes.

### Phase 3: Testing

-   [x] **`FcpSurfaceManager` Tests:**
    -   [x] Create `pkgs/spikes/fcp_tools/test/fcp_surface_manager_test.dart`.
    -   [x] Write unit tests for all methods in `FcpSurfaceManager`.
-   [x] **`manage_ui` Tool Tests:**
    -   [x] Create `pkgs/spikes/fcp_tools/test/tools/manage_ui_test.dart`.
    -   [x] Write unit tests for each action in the `manage_ui` tool, mocking the `FcpSurfaceManager`.
-   [x] **`get_widget_catalog` Tool Tests:**
    -   [x] Create `pkgs/spikes/fcp_tools/test/tools/get_widget_catalog_test.dart`.
    -   [x] Write unit tests for the `get_widget_catalog` tool.

### Phase 4: Example Application

-   [x] **Create Example App:**
    -   [x] Create a new Flutter application in the `example` directory.
    -   [x] Add a dependency on `fcp_tools`, `ai_client`, and `fcp_client`.
-   [x] **Implement Chat UI:**
    -   [x] Create a simple chat interface with a text input and a conversation view.
-   [x] **Integrate `FcpSurfaceManager`:**
    -   [x] Instantiate `FcpSurfaceManager` in the main application widget.
    -   [x] Create a dedicated area in the UI to display the surfaces managed by the `FcpSurfaceManager`.
-   [x] **Integrate AI Client and Tools:**
    -   [x] Instantiate `GeminiAiClient` (or another `AiClient` implementation).
    -   [x] Instantiate the `fcp_tools` and pass them to the `AiClient`.
    -   [x] Connect the chat UI to the `AiClient` to send prompts and receive responses.

## 4. `pubspec.yaml` for `fcp_tools`

```yaml
name: fcp_tools
description: A package providing AI tools for dynamically creating and manipulating a Flutter user interface with FCP.
version: 0.1.0
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=1.17.0"

dependencies:
  ai_client:
    path: ../ai_client
  dart_schema_builder:
    path: ../../dart_schema_builder
  fcp_client:
    path: ../fcp_client
  flutter:
    sdk: flutter

dev_dependencies:
  lints: ^4.0.0
  test: ^1.24.0
```

## 5. Success Criteria

The task will be considered complete when:

1.  The `pkgs/spikes/fcp_tools` directory contains a fully-formed, self-contained Dart package.
2.  The `FcpSurfaceManager` and all specified AI tools are implemented and unit-tested.
3.  The example application is fully functional and demonstrates the conversational UI generation capabilities of the package.
4.  The new package passes all static analysis checks (`dart analyze`).
5.  All tests pass.