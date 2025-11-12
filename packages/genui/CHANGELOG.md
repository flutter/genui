# `genui` Changelog

## 0.5.2 (in progress)

## 0.5.1

- Homepage URL was updated.
- Deprecated `flutter_markdown` package was replaced with `flutter_markdown_plus`.

## 0.5.0

- Initial published release.

## 0.4.0

- **BREAKING**: Replaced `AiClient` interface with `ContentGenerator`. `ContentGenerator` uses a stream-based API (`a2uiMessageStream`, `textResponseStream`, `errorStream`) for asynchronous communication of AI-generated UI commands, text, and errors.
- **BREAKING**: `GenUiConversation` now requires a `ContentGenerator` instance instead of an `AiClient`.
- **Feature**: Introduced `A2uiMessage` sealed class (`BeginRendering`, `SurfaceUpdate`, `DataModelUpdate`, `SurfaceDeletion`) to represent AI-to-UI commands, emitted from `ContentGenerator.a2uiMessageStream`.
- **Feature**: Added `FakeContentGenerator` for testing purposes, replacing `FakeAiClient`.
- **Feature**: Added `configureGenUiLogging` function and `genUiLogger` instance for configurable package logging.
- **Feature**: Added `JsonMap` type alias in `primitives/simple_items.dart`.
- **Feature**: Added `DirectCallHost` and related utilities in `facade/direct_call_integration` for more direct AI model interactions.
- **Refactor**: `GenUiConversation` now internally subscribes to `ContentGenerator` streams and uses callbacks (`onSurfaceAdded`, `onSurfaceUpdated`, `onSurfaceDeleted`, `onTextResponse`, `onError`) to notify the application of events.
- **Fix**: Improved error handling and reporting through the `ContentGenerator.errorStream` and `ContentGeneratorError` class.

## 0.2.0

- **BREAKING**: Replaced `ElevatedButton` with a more generic `Button` component.
- **BREAKING**: Removed `CheckboxGroup` and `RadioGroup` from the core catalog. The `MultipleChoice` or `CheckBox` widgets can be used as replacements.
- **Feature**: Added an `obscured` property to `TextInputChip` to allow for password style inputs.
- **Feature**: Added many new components to the core catalog: `AudioPlayer` (placeholder), `Button`, `Card`, `CheckBox`, `DateTimeInput`, `Divider`, `Heading`, `List`, `Modal`, `MultipleChoice`, `Row`, `Slider`, `Tabs`, and `Video` (placeholder).
- **Fix**: Corrected the action key from `actionName` to `name` in `Trailhead` and `TravelCarousel`.
- **Fix**: Corrected the image property from `location` to `url` in `TravelCarousel`.

## 0.1.0

- Initial commit
