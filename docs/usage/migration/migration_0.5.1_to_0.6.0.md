# Migration Guide: 0.5.1 to 0.6.0

This guide covers the migration steps for upgrading from `genui` version 0.5.1 to 0.6.0. This release introduces significant breaking changes, primarily the renaming of `GenUiManager` and the removal of `GenUiConfiguration`.

## `GenUiManager` Renamed to `A2uiMessageProcessor`

The `GenUiManager` class has been renamed to `A2uiMessageProcessor` to better reflect its responsibility of processing A2UI messages.

**Before:**
```dart
final genUiManager = GenUiManager(catalog: catalog);
```

**After:**
```dart
final a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);
```

**Key Changes:**
1.  **Class Rename:** `GenUiManager` is now `A2uiMessageProcessor`.
2.  **Multiple Catalogs:** The constructor now accepts `catalogs` (an `Iterable<Catalog>`) instead of a single `catalog`.

## `GenUiConversation` Updates

The `GenUiConversation` constructor has been updated to accept `a2uiMessageProcessor` instead of `genUiManager`.

**Before:**
```dart
GenUiConversation(
  genUiManager: genUiManager,
  contentGenerator: contentGenerator,
  // ...
);
```

**After:**
```dart
GenUiConversation(
  a2uiMessageProcessor: a2uiMessageProcessor,
  contentGenerator: contentGenerator,
  // ...
);
```

## `GenUiConfiguration` Removed

The `GenUiConfiguration` class and the `configuration` parameter in `ContentGenerator` constructors (including `FirebaseAiContentGenerator` and `GoogleGenerativeAiContentGenerator`) have been removed.

-   **All Actions Enabled:** Previously, you could use `ActionsConfig` to enable or disable specific A2UI actions (create, update, delete). In 0.6.0, these tools (`SurfaceUpdateTool`, `BeginRenderingTool`, `DeleteSurfaceTool`) are added by default.
-   **Parameter Removal:** Remove the `configuration` argument from your `ContentGenerator` instantiation.

**Before:**
```dart
final contentGenerator = FirebaseAiContentGenerator(
  catalog: catalog,
  configuration: const GenUiConfiguration(
    actions: ActionsConfig(allowDelete: false),
  ),
);
```

**After:**
```dart
final contentGenerator = FirebaseAiContentGenerator(
  catalog: catalog,
);
```

## `GenUiHost` Changes

If you are implementing custom `GenUiHost` (or mocking it):
-   `get catalog` has been replaced with `get catalogs`, which returns `Iterable<Catalog>`.
