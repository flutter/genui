# Migration Guide: A2UI v0.9 to v1.0

The packages in this repository now implement
[A2UI protocol v1.0](https://a2ui.org/specification/v1.0-evolution-guide/)
instead of v0.9/v0.9.1. Apps that only use the default AI/transport flow and
the basic catalog widgets keep working, but any server, agent prompt, or test
fixture that produces or consumes raw A2UI JSON must be updated.

## Wire format changes

### Version envelopes

Every streamed JSON envelope must use `"version": "v1.0"`. Messages with any
other version are rejected with a validation error.

### `createSurface`

- The `theme` field is renamed to `surfaceProperties`, and `primaryColor` is
  removed. Surface properties (e.g. `agentDisplayName`, `iconUrl`) are
  validated against the catalog's `surfaceProperties` schema.
- Initial `components` and `dataModel` can now be passed directly inside the
  `createSurface` payload, so an entire UI can be created in one message.
- `surfaceId` must be unique for the renderer's lifetime; re-creating an
  existing surface without deleting it first is an error.

```json
// Before (v0.9)
{"version": "v0.9", "createSurface": {"surfaceId": "s", "catalogId": "c",
  "theme": {"primaryColor": "#FF0000"}}}

// After (v1.0)
{"version": "v1.0", "createSurface": {"surfaceId": "s", "catalogId": "c",
  "surfaceProperties": {"agentDisplayName": "My Agent"},
  "components": [{"id": "root", "component": "Text", "text": "Hi"}],
  "dataModel": {"user": {"name": "Alice"}}}}
```

### `updateDataModel`

Deletion is now explicit: set the path's `value` to `null` to delete the key
at that path. Omitting keys no longer indicates deletion.
`UpdateDataModelMessage.toJson()` serializes `"value": null` accordingly.

### Function calls

Wire-level `FunctionCall` objects no longer carry `returnType` (or
`callableFrom`); both are static metadata in catalog function definitions and
are enforced at runtime.

## New messages

### Server → client

- `callFunction` (with a top-level `functionCallId` and optional
  `wantResponse`) executes a catalog function on the client. Functions must be
  registered with `callableFrom` of `remoteOnly` or `clientOrRemote`;
  otherwise the client replies with an `INVALID_FUNCTION_CALL` error.
- `actionResponse` (with a top-level `actionId`) answers a client action that
  set `wantResponse: true`, carrying exactly one of `value` or `error`. The
  client writes `value` into the data model at the action's `responsePath`.

### Client → server

- `functionResponse` returns the result of a `callFunction` invocation,
  echoing `functionCallId` and `call`.
- `action` messages may carry `wantResponse` and a generated `actionId`.
- `error` messages may carry `functionCallId` instead of `surfaceId` (exactly
  one of the two) when reporting function execution failures.

## Catalog changes

- The `functions` property is a map keyed by function name (previously an
  array). Each definition validates the wire `FunctionCall` and carries
  static `returnType` and `callableFrom` metadata.
- `$defs/theme` is replaced by `$defs/surfaceProperties`; inline catalogs also
  advertise `$defs/anyComponent` and `$defs/anyFunction`.
- An optional `instructions` field embeds Markdown design guidelines directly
  in the catalog (genui serializes `Catalog.systemPromptFragments` there).
- Catalog entity names (components, functions) must conform to UAX #31
  identifier rules; invalid names throw at catalog construction.
- The basic catalog id is now
  `https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json`
  (`basicCatalogId`).

## Component and evaluation changes

- `TextField` supports `placeholder`, `Slider` supports `steps`, and `Video`
  supports `posterUrl`.
- The `@index` built-in function returns the 0-based iteration index inside
  template instantiation loops (optionally shifted by an `offset` argument).
  The `@` prefix is reserved for system functions; `@index` outside a template
  loop is an evaluation error.

## Dart API renames

| Before | After |
| --- | --- |
| `CreateSurfaceMessage.theme` | `CreateSurfaceMessage.surfaceProperties` |
| `SurfaceModel.theme` | `SurfaceModel.surfaceProperties` |
| `SurfaceDefinition.theme` | `SurfaceDefinition.surfaceProperties` |
| `core.Catalog.themeSchema` | `core.Catalog.surfacePropertiesSchema` |

## Transport metadata

- The A2A extension URI is now `https://a2ui.org/a2a-extension/a2ui/v1.0`.
- Client capabilities and client data-model envelopes are namespaced under
  `v1.0` (previously `v0.9`).
- The standardized MIME type for A2UI payloads is `application/a2ui+json`.
