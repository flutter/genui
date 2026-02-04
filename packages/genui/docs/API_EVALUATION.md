# API Review: `packages/genui`

## Executive Summary

**Score: B+**

The `packages/genui` package demonstrates a solid architectural foundation with a strong focus on type safety, clear separation of concerns in its data models, and adherence to "Contract-First" design via rigorous validation. However, significant violations of **Encapsulation (Information Hiding)**, **Orthogonality**, and **Operational Reliability** (Global Side Effects) drag down the score. Addressing these issues is critical to preventing technical debt and usage friction.

## Critical Issues

### 1. Hardcoded "showModal" Logic (Open/Closed Principle Violation)
**File:** `lib/src/widgets/genui_surface.dart`
**Principle:** *Orthogonality & Separation of Concerns*

The `GenUiSurface` widget contains hardcoded logic for handling a specific 'showModal' event name. This restricts the framework's ability to handle other types of generic UI actions (like dialogs, toasts, or platform-specific views) without modifying the core widget itself.

**Recommendation:**
Refactor the event dispatching mechanism to delegate action handling to a pluggable strategy or the `GenUiHost`/`GenUiContext`.

**Code Example:**

*Before:*
```dart
// lib/src/widgets/genui_surface.dart

void _dispatchEvent(UiEvent event) {
  if (event is UserActionEvent && event.name == 'showModal') {
    // ... ~30 lines of specific modal building logic ...
    showModalBottomSheet<void>(...);
    return;
  }
  // ... generic dispatch ...
}
```

*After:*
```dart
// lib/src/widgets/genui_surface.dart

void _dispatchEvent(UiEvent event) {
  // Delegate all action handling to the context/host
  // The host can decide if "showModal" means a bottom sheet, a dialog, or a new window.
  widget.genUiContext.handleUiEvent(event);
}
```

*In the Default Implementation (e.g., GenUiEngine/Context):*
```dart
// lib/src/engine/gen_ui_engine.dart

void handleMessage(UiEvent event) {
  if (event is UserActionEvent && event.name == 'showModal') {
     // Handle modal logic here, or emit a "ShowModal" intent
     // that the platform embedding layer listens to.
  }
}
```

### 2. Leaky Abstractions via Unexported Types
**File:** `lib/src/engine/gen_ui_engine.dart`
**Principle:** *Minimal Surface Area*

`GenUiEngine` exposes `registry` (returning `SurfaceRegistry`) and `store` (returning `DataModelStore`) as public getters. However, `SurfaceRegistry` is not exported by `genui.dart` (only `RegistryEvent` is).
*   **Problem:** Consumers receive an object of a type they cannot reference or import.
*   **Recommendation:** Make `registry` and `store` private or `@internal`. Consumers should interact with the engine via its primary interface (`handleMessage`, `contextFor`).

### 3. Unsafe Global Side Effects in Logging
**File:** `lib/src/primitives/logging.dart`
**Principle:** *Operational Reliability & Principle of Least Astonishment*

The `configureGenUiLogging` function modifies global static state in the `logging` package:
1.  `hierarchicalLoggingEnabled = true;`
2.  `recordStackTraceAtLevel = Level.SEVERE;`
3.  It attaches a **new listener** to `Logger.root.onRecord` every time it is called, leading to duplicate logs and memory leaks if called multiple times.

**Recommendation:**
*   Add an optional parameter `bool enableHierarchicalLogging = true` to the function.
*   This explicitly informs the consumer that a global change will occur, satisfying the *Principle of Least Astonishment*.
*   Manage the static subscription (check if it exists or allow `dispose`) to avoid duplicate listeners.

**Code Example:**

*Before:*
```dart
Logger configureGenUiLogging({...}) {
  hierarchicalLoggingEnabled = true; // GLOBAL SIDE EFFECT!
  Logger.root.onRecord.listen(...); // ADDS DUPLICATE LISTENER!
}
```

*After:*
```dart
StreamSubscription<LogRecord>? _subscription;

/// Returns a subscription that must be cancelled by the caller.
StreamSubscription<LogRecord> configureGenUiLogging({
  Level level = Level.INFO,
  bool enableHierarchicalLogging = true, // Explicit opt-in
}) {
  if (enableHierarchicalLogging) {
    hierarchicalLoggingEnabled = true;
  }

  genUiLogger.level = level;

  _subscription?.cancel(); // Cancel previous
  return Logger.root.onRecord.listen(...);
}
```

## Important Findings & Recommendations

### 1. Main Namespace Pollution
**File:** `lib/genui.dart`
**Observation:** `export 'src/utils/json_block_parser.dart';`
**Context:** The user intends for this to be a building block for custom parsers.
**Recommendation:** Move this export to a separate library file (e.g., `package:genui/parsing.dart`).
*   **Reasoning:** Keeping the main `package:genui/genui.dart` import focused on the core "Happy Path" reduces cognitive load for standard users (`KISS` principle). Advanced users can explicitly import the parsing tools when needed.

### 2. Conflating Transport and User Interaction
**File:** `lib/src/engine/gen_ui_engine.dart`
**Observation:** `handleMessage` catches internal validation errors and emits them as `ChatMessage.user` on the `onSubmit` stream.
**Problem:** This disguises system errors as user input, which is conceptually confusing and makes error handling difficult for the host application.
**Recommendation:** Use a dedicated error stream or specific error types for validation failures.

### 3. "Stringly-Typed" APIs
**File:** `lib/src/model/a2ui_message.dart`
**Observation:** `UpdateDataModel` accepts raw strings for `path` (e.g., `'/'`).
**Recommendation:** Update `UpdateDataModel` to use the existing `DataPath` class instead of raw strings to prevent runtime typos.

### 4. Naming Clarity
**Observation:** `GenUiEngine` is a generic name for the central runtime class.
**Recommendation:** Consider `GenUiController` if the class primarily manages the active runtime state of surfaces, aligning with standard Flutter conventions (e.g. `AnimationController`). "Engine" is acceptable but often implies a lower-level driver.

## Good Practices (Keep)

*   **Robust Contract Enforcement:** Manual `UiDefinition.validate()` ensures strict schema adherence (Postel's Law - verify before processing).
*   **Sealed Classes:** `sealed class A2uiMessage` provides exhaustive strictness and safety.
*   **Extension Types:** `UiEvent` offers zero-cost abstraction, though we suggest adding safety guards for missing keys.
