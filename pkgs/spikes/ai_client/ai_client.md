# AI Client Package Factoring Plan

This document outlines the plan to extract the AI client functionality from the `flutter_genui` package into a new, self-contained package named `ai_client`. This new package will be located at `pkgs/spikes/ai_client`.

## 1. Goals

- **Decoupling:** Create a general-purpose AI client package that is not tied to the `flutter_genui` widget rendering system.
- **Reusability:** Allow the new `ai_client` package to be used by `fcp_tools`, and eventually by `flutter_genui` itself, as well as other future packages.
- **Maintainability:** Isolate the logic for communicating with AI models, making it easier to maintain and update independently.

## 2. New Package Structure

The new package will be created at `pkgs/spikes/ai_client` with the following structure:

```txt
pkgs/spikes/ai_client/
├── lib/
│   ├── src/
│   │   ├── ai_client.dart
│   │   ├── gemini_ai_client.dart
│   │   ├── gemini_content_converter.dart
│   │   ├── gemini_schema_adapter.dart
│   │   ├── generative_model_interface.dart
│   │   ├── tools.dart
│   │   └── model/
│   │       └── chat_message.dart
│   ├── ai_client.dart  (exports)
│   └── test.dart       (exports test utilities)
├── test/
│   └── fake_ai_client.dart
├── analysis_options.yaml
├── CHANGELOG.md
├── LICENSE
├── pubspec.yaml
└── README.md
```

## 3. Detailed Checklist

### Phase 1: Package Scaffolding

- [ ] Create the root directory: `pkgs/spikes/ai_client`.
- [ ] Create the `lib`, `lib/src`, `lib/src/model`, and `test` directories.
- [ ] Create a `pubspec.yaml` file with the necessary dependencies.
- [ ] Create a standard `analysis_options.yaml` file.
- [ ] Add `README.md`, `CHANGELOG.md`, and `LICENSE` files.

### Phase 2: Code Migration and Refactoring

- [ ] **Copy Core Logic:** Copy the following files from `pkgs/flutter_genui/lib/src/ai_client/` to `pkgs/spikes/ai_client/lib/src//`:
  - `ai_client.dart`
  - `gemini_ai_client.dart`
  - `gemini_content_converter.dart`
  - `gemini_schema_adapter.dart`
  - `generative_model_interface.dart`
  - `tools.dart`
- [ ] **Decouple ChatMessage:** The `gemini_content_converter.dart` file depends on `ChatMessage` from `flutter_genui`.
  - [ ] Copy the contents of `pkgs/flutter_genui/lib/src/model/chat_message.dart` into a new file at `pkgs/spikes/ai_client/lib/src/model/chat_message.dart`.
  - [ ] Remove the `UiResponseMessage` class from the new `chat_message.dart` as it is specific to `flutter_genui`.
- [ ] **Update Imports:** Adjust all `import` statements in the copied files to use correct relative paths or `package:ai_client/...` paths. Ensure there are no more references to `package:flutter_genui/...`.
- [ ] **Create Public API:** Create the main library file `pkgs/spikes/ai_client/lib/ai_client.dart` that exports the necessary classes and models (`AiClient`, `GeminiAiClient`, `AiTool`, `ChatMessage`, etc.).
- [ ] **Migrate Test Utilities:**
  - [ ] Copy `pkgs/flutter_genui/lib/test/fake_ai_client.dart` to `pkgs/spikes/ai_client/test/fake_ai_client.dart`.
  - [ ] Update the `fake_ai_client.dart` to import from the new `ai_client` package instead of `flutter_genui`.
  - [ ] Create `pkgs/spikes/ai_client/lib/test.dart` to export the `FakeAiClient` for easy consumption by other packages.

### Phase 3: Verification

- [ ] **Resolve Dependencies:** Run `dart pub get` in the `pkgs/spikes/ai_client` directory.
- [ ] **Static Analysis:** Run `dart analyze` to ensure the new package has no analysis errors or warnings.
- [ ] **Testing:** Create a basic test file in `test/` that imports `fake_ai_client.dart` and runs a simple test to confirm the test environment is working correctly.
- [ ] Copy over any existing tests for `AiClient` or its components and adapt their imports.

## 4. `pubspec.yaml` for `ai_client`

```yaml
name: ai_client
description: A package for interacting with AI models, providing a generic client interface and a Gemini implementation.
version: 0.1.0
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=1.17.0"

dependencies:
  dart_schema_builder:
    path: ../../dart_schema_builder
  firebase_ai: ^0.3.0
  file: ^7.0.0
  flutter:
    sdk: flutter

dev_dependencies:
  lints: ^4.0.0
  test: ^1.24.0
```

## 5. Success Criteria

The task will be considered complete when:

1. The `pkgs/spikes/ai_client` directory contains a fully-formed, self-contained Dart package.
2. The new `ai_client` package has **zero** dependencies on the `flutter_genui` package.
3. All code from the `flutter_genui/lib/src/ai_client/` directory has been successfully migrated and refactored.
4. The new package passes all static analysis checks (`dart analyze`).
5. The `flutter_genui` package remains unchanged in this process.
6. No static analysis errors, warnings, or infos exist in the `ai_client` package.
7. All tests can be successfully run within the new package.
