# Migration Guide: 0.9.1 to 0.10.0

`package:genui` now runs on the shared `package:a2ui_core` runtime (#811). The
only customer-facing change is for code that **implements a custom `Transport` or
constructs/parses A2UI messages directly** — those message types moved to
`a2ui_core`. The default AI/transport flow, catalog widgets, and data-binding code
are unaffected.

## What you have to change

### A2UI messages are now `a2ui_core` types

The genui message classes (`A2uiMessage`, `CreateSurface`, `UpdateComponents`,
`UpdateDataModel`, `DeleteSurface`) are removed. Add `a2ui_core` to your
dependencies and use its message types. They don't collide with anything genui
exports, so import them unprefixed with a `show` list:

```dart
// Before
controller.handleMessage(
  UpdateComponents(surfaceId: 's', components: [
    Component(id: 'root', type: 'Text', properties: {'text': 'Hi'}),
  ]),
);
controller.handleMessage(CreateSurface(surfaceId: 's', catalogId: 'demo'));

// After
import 'package:a2ui_core/a2ui_core.dart'
    show CreateSurfaceMessage, UpdateComponentsMessage;

controller.handleMessage(
  UpdateComponentsMessage(surfaceId: 's', components: [
    {'id': 'root', 'component': 'Text', 'text': 'Hi'},
  ]),
);
controller.handleMessage(
  CreateSurfaceMessage(surfaceId: 's', catalogId: 'demo'),
);
```

- **Custom transport:** `Transport.incomingMessages` and
  `SurfaceController.handleMessage` now use `a2ui_core`'s `A2uiMessage`. Update
  those signatures if you implement `Transport` or drive the controller directly.
- **Building messages:** `UpdateComponentsMessage` takes raw component JSON maps
  (`{'id': ..., 'component': ..., ...props}`), not `Component` objects.
- **Parsing raw JSON:** use `A2uiMessage.fromJson(json)`.

### `SurfaceController.store` is removed

Read a surface's data model via `SurfaceController.contextFor(id).dataModel`.

## Behavior you may notice

- **`DataModel` writes are stricter.** Some writes that used to silently do
  nothing now throw, e.g. writing through a path whose intermediate value isn't a
  map or list.
- **Malformed messages are rejected more consistently** (missing or wrong
  version, or more than one action key in a single message).
- **A duplicate `createSurface` for an active surface id is now an error** rather
  than silently reusing the existing surface.
- **`updateDataModel` with `value: null` removes the key**, the same as omitting
  the value. Distinguishing the two is pending flutter/genui#938.

## What does not change

Your catalog widgets and data-binding code are untouched: `CatalogItemContext`,
`dataContext`, the `DataModel` / `DataPath` API, the `Bound*` widgets, and the
`SurfaceDefinition` / `Component` snapshots all keep their current shape.

A follow-up (#801) will unify these with the `a2ui_core` models once the upstream
Node Layer (A2UI#1282) lands.
