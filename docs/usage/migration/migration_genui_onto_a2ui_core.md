# Migration Guide: GenUI on `a2ui_core`

`package:genui` now runs on the shared `package:a2ui_core` runtime (#811). This
changes how you feed A2UI messages to genui. Catalog widgets and data-binding
code are unaffected.

## What you have to change

### A2UI messages are now `a2ui_core` types

The genui message classes (`A2uiMessage`, `CreateSurface`, `UpdateComponents`,
`UpdateDataModel`, `DeleteSurface`) are removed. If you construct or handle
messages directly, switch to the `a2ui_core` types and add `a2ui_core` to your
dependencies.

```dart
// Before
controller.handleMessage(
  UpdateComponents(surfaceId: 's', components: [
    Component(id: 'root', type: 'Text', properties: {'text': 'Hi'}),
  ]),
);
controller.handleMessage(CreateSurface(surfaceId: 's', catalogId: 'demo'));

// After
import 'package:a2ui_core/a2ui_core.dart' as core;

controller.handleMessage(
  core.UpdateComponentsMessage(surfaceId: 's', components: [
    {'id': 'root', 'component': 'Text', 'text': 'Hi'},
  ]),
);
controller.handleMessage(
  core.CreateSurfaceMessage(surfaceId: 's', catalogId: 'demo'),
);
```

- `handleMessage`, `Transport.incomingMessages`, and `A2uiMessageEvent.message`
  now use `core.A2uiMessage`.
- `core.UpdateComponentsMessage` takes raw component JSON maps
  (`{'id': ..., 'component': ..., ...props}`), not `Component` objects.
- Parse from JSON with `core.A2uiMessage.fromJson(json)`.

### `SurfaceController.store` is removed

Read a surface's data model via `SurfaceController.contextFor(id).dataModel`
(writable, and usable before the surface is created).

## Behavior you may notice

- **`DataModel` writes are stricter.** Writes that previously did nothing can now
  throw, e.g. type-mismatched intermediate paths and out-of-range list indices;
  sparse list writes fill the gaps with `null`.
- **Malformed messages are rejected more consistently** (missing or wrong
  version, or more than one action key in a single message).
- **A duplicate `createSurface` for an active surface id is now an error** rather
  than silently reusing the existing surface.
- **JSON Pointer `~0`/`~1` escapes are no longer interpreted** in data paths;
  paths split on `/`.
- **`updateDataModel` with `value: null` removes the key**, the same as omitting
  the value. Distinguishing the two is pending flutter/genui#938.

## What does not change

Your catalog widgets and data-binding code are untouched: `CatalogItemContext`,
`dataContext`, the `DataModel` / `DataPath` API, the `Bound*` widgets, and the
`SurfaceDefinition` / `Component` snapshots all keep their current shape.

A follow-up (#801) will unify these with the `a2ui_core` models once the upstream
Node Layer (A2UI#1282) lands.
