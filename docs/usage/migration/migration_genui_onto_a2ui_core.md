# Migration Guide: GenUI on `a2ui_core`

This PR migrates `package:genui`'s runtime substrate onto the shared
`package:a2ui_core` implementation, but it intentionally keeps the existing
GenUI-facing API shape as a compatibility facade.

The goal is to make this PR about the substrate swap (#811): shared protocol
parsing, shared surface/data-model state, and granular Flutter rebuilds. Public
API renames for closer web/core parity are deferred to a follow-up PR (#801).

## What stays source-compatible in this PR

GenUI applications and catalog authors should continue to use the existing
`package:genui` API names:

- `CreateSurface`, `UpdateComponents`, `UpdateDataModel`, `DeleteSurface`, and
  `A2uiMessage.fromJson`.
- `DataPath`, `DataModel`, `InMemoryDataModel`, `DataContext.update`,
  `getValue`, `subscribe`, and `bindExternalState`.
- `Component` and `SurfaceDefinition` snapshot/value objects.
- `SurfaceContext.definition`, `SurfaceUpdate.definition`, and `SurfaceController.store` / `DataModelStore`.
- `ActionDelegate.handleEvent`'s existing `SurfaceDefinition` callback shape.
- Catalog widget authoring through `CatalogItemContext.id`, `type`, `data`,
  `surfaceId`, `getComponent`, `dataContext`, `buildChild`, `dispatchEvent`,
  and `reportError`.
- `UiPart.create(definition: SurfaceDefinition(...))`.

You should **not** need to add `a2ui_core` to application/example packages just
to consume GenUI. `package:genui` does not re-export raw `a2ui_core` symbols.

## What changed internally

The compatibility types above now delegate to, wrap, or snapshot from
`a2ui_core`:

- `SurfaceController.handleMessage(...)` accepts GenUI facade messages, converts
  them to core messages privately, and delegates state mutation to
  `a2ui_core.MessageProcessor`.
- `InMemoryDataModel` wraps `a2ui_core.DataModel` while preserving the old
  `DataPath`/`ValueListenable` API.
- GenUI's own `SurfaceController` + `Surface` path renders from the live core
  `SurfaceModel`, so component updates can rebuild only the affected component
  subtree.
- `SurfaceController.store` remains available as a compatibility facade; for
  live surfaces it returns wrappers around the surface's core-backed data model.
- Custom/external `SurfaceContext` implementations can still provide only the
  legacy `definition` snapshot path.
- `CatalogItemContext` is internally backed by `a2ui_core.ComponentContext`, but
  the public authoring surface remains the GenUI shim getters and callbacks.
  `getComponent()` returns a GenUI `Component?` snapshot.

## Remaining behavior changes to watch for

These are substrate behavior changes, not rename requirements:

1. **`DataModel` is stricter.** Some writes that previously no-op'd now throw
   core data errors, especially type-mismatched intermediate paths and very
   large list indices. Sparse list writes are also core-style: skipped entries
   are filled with `null`.
2. **Stored containers are mutable copies.** Incoming map/list values are copied
   before storage so nested updates work even when callers pass const literals.
3. **Surfaces are live internally.** Public `SurfaceDefinition` snapshots remain
   available, but GenUI's built-in renderer uses live component models for
   granular rebuilds.
4. **Data reactivity is signal-backed internally.** Public `subscribe(...)`
   still returns a `ValueListenable`, and `Bound*` widgets keep their existing
   API. Internally, those listenables bridge to `preact_signals` from
   `a2ui_core`.
5. **Protocol validation is stricter.** The core parser rejects malformed
   envelopes more consistently, including missing/incorrect versions and
   envelopes with more than one action key.
6. **Duplicate `createSurface` for an active surface id is an error** instead
   of silently reusing the existing surface.
7. **JSON Pointer `~0`/`~1` escapes are not interpreted.** Paths split on `/`,
   matching the web core behavior.

## On the future of the compatibility facades

The GenUI-named types in this release (`CreateSurface`, `InMemoryDataModel`,
`DataPath`, `SurfaceDefinition`, `Component`, `SurfaceContext.definition`,
`SurfaceController.store`, etc.) are kept as a compatibility API on top of
`a2ui_core`. They're stable; you can write new code against them today.

A future PR may add `a2ui_core`-shaped aliases or replacements for closer
cross-language parity (`CreateSurfaceMessage`, string paths, `SurfaceModel`,
raw map component payloads, etc.). That PR is not scheduled, and the existing
GenUI names will not be removed without a separate deprecation cycle. Treat
the facade types in this release as the current public API, not as
short-lived shims.
