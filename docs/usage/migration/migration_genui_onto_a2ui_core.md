# Migration Guide: GenUI on `a2ui_core`

`package:genui`'s runtime substrate now runs on the shared `package:a2ui_core`
implementation: shared protocol parsing, message processing, and
surface/data-model state (#811).

This migration unifies the **message layer** with `a2ui_core` directly. The
catalog-widget authoring API is intentionally left unchanged, pending the
typed-props authoring API (flutter/genui#801) and the upstream Node Layer
(A2UI#1282). So the surface/component snapshot types and the data-model API are
retained for now as GenUI types.

## Breaking changes

### A2UI messages are now `a2ui_core` types

The GenUI message classes (`A2uiMessage`, `CreateSurface`, `UpdateComponents`,
`UpdateDataModel`, `DeleteSurface`) are removed. Use the `a2ui_core` types
directly:

- Add `a2ui_core` as a dependency of any package that builds or inspects A2UI
  messages.
- `SurfaceController.handleMessage`, `Transport.incomingMessages`, and
  `A2uiMessageEvent.message` now use `core.A2uiMessage`.
- Construct messages with `core.CreateSurfaceMessage(...)`,
  `core.UpdateComponentsMessage(...)`, `core.UpdateDataModelMessage(...)` /
  `.removeKey(...)`, and `core.DeleteSurfaceMessage(...)`.
- `core.UpdateComponentsMessage.components` is a `List<Map<String, dynamic>>` of
  raw component wire JSON (`{'id': ..., 'component': ..., ...props}`), not
  `Component` objects.
- Parse from JSON with `core.A2uiMessage.fromJson(json)`.

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

### `SurfaceController.store` / `DataModelStore` removed

Read a surface's data model directly:

- `SurfaceController.contextFor(id).dataModel` is writable, and usable before the
  surface is created (the data is migrated into the live model on creation).
- `SurfaceController.registry.getSurface(id)?.dataModel` once the surface exists.

### `SurfaceRegistry.updateSurface(...)` removed

Surface lifecycle updates flow through `SurfaceController.handleMessage`; the
definition-only push path is no longer supported. `addSurface` and
`notifyUpdated` remain on `SurfaceRegistry` but are marked `@internal`.

## What stays the same (for now)

These are unchanged by this migration and remain GenUI types, pending #801:

- **Catalog widget authoring.** `CatalogItemContext.id`, `type`, `data`,
  `surfaceId`, `getComponent` (returns a `Component?` snapshot), `dataContext`,
  `buildChild`, `dispatchEvent`, and `reportError`. Catalog widget bodies do not
  change.
- **Data model API.** `DataPath`, `DataModel`, `InMemoryDataModel`,
  `DataContext.update` / `getValue` / `subscribe` / `bindExternalState`, and the
  `Bound*` widgets.
- **Surface snapshots.** `Component`, `SurfaceDefinition`,
  `SurfaceContext.definition`, `SurfaceUpdate.definition`,
  `ActionDelegate.handleEvent`'s `SurfaceDefinition` callback, and
  `UiPart.create(definition: SurfaceDefinition(...))`.

Internally these wrap or snapshot from `a2ui_core`: `InMemoryDataModel` wraps
`a2ui_core.DataModel`; `CatalogItemContext` is backed by
`a2ui_core.ComponentContext`; `SurfaceDefinition` is a snapshot of the live
`a2ui_core.SurfaceModel`.

The live core model is reachable through a few `@internal` APIs
(`SurfaceAdded.surface`, `ComponentsUpdated.surface`,
`SurfaceRegistry.watchLiveSurface` / `getLiveSurface`). Prefer
`SurfaceUpdate.definition` or `SurfaceRegistry.getSurface` / `watchSurface`
(which return `SurfaceDefinition`) unless you specifically need live core access.

## Behavior changes to watch for

These come from the `a2ui_core` substrate, independent of any rename:

1. **`DataModel` is stricter.** Writes that previously no-op'd now throw core
   data errors, especially type-mismatched intermediate paths and very large
   list indices. Sparse list writes fill skipped entries with `null`.
2. **Stored containers are mutable copies.** Incoming map/list values are copied
   before storage so nested updates work even when callers pass const literals.
3. **Data reactivity is signal-backed internally.** `subscribe(...)` still
   returns a `ValueListenable` and the `Bound*` widgets keep their API;
   internally those listenables bridge to `preact_signals`.
4. **Protocol validation is stricter.** The core parser rejects malformed
   messages more consistently, including missing/incorrect versions and messages
   with more than one top-level action key.
5. **Duplicate `createSurface` for an active surface id is an error** instead of
   silently reusing the existing surface.
6. **JSON Pointer `~0`/`~1` escapes are not interpreted.** Paths split on `/`,
   matching the web core behavior (A2UI#1499 tracks the spec clarification).
7. **The renderer rebuilds from the `SurfaceDefinition` snapshot.** The built-in
   `Surface` rebuilds when a surface's snapshot changes; data-bound values update
   through the `Bound*` widgets.
8. **`core.UpdateDataModelMessage.hasValue`** distinguishes `value: null` from an
   omitted `value` on the wire, but runtime mutation currently treats both as
   "remove the key" (flutter/genui#938, A2UI#1504).

## Still deferred

- The catalog widget authoring API stays on `CatalogItemContext`; a typed-props
  API (#801) is on hold until A2UI#1282 settles.
- Action dispatch and `sendDataModel` synchronization still flow through the
  existing GenUI path rather than `core.SurfaceGroupModel.onAction` or
  `MessageProcessor.getClientDataModel()`.
- `GenericBinder` is not exposed as a Flutter-side public API.

## What's next

A follow-up (#801), gated on the upstream Node Layer (A2UI#1282), will unify the
retained GenUI types (`Component`, `SurfaceDefinition`, the `DataModel` API,
`SurfaceContext.definition`) with the `a2ui_core` models so the catalog authoring
API can move onto core types too. Until then, the types under "What stays the
same" are the current public API.
