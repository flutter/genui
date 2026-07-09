# `a2ui_core` Changelog

## Next

- **BREAKING**: Migrated to A2UI protocol v1.0. Message envelopes now use
  `version: "v1.0"`; `CreateSurfaceMessage.theme` is renamed to
  `surfaceProperties` and supports inline `components` and `dataModel`;
  `updateDataModel` serializes an explicit `null` to delete keys; wire-level
  `returnType` is removed from `FunctionCall`.
- **Feature**: Server-initiated function calls (`CallFunctionMessage`) with
  `callableFrom` runtime boundary checks and `A2uiFunctionResponse` replies.
- **Feature**: Synchronous action responses: `A2uiClientAction` gains
  `wantResponse`/`actionId`, and `ActionResponseMessage` values are written to
  the data model at the action's `responsePath`.
- **Feature**: `@index` system function (with optional `offset`) inside
  template instantiation loops; the `@` prefix is reserved.
- **Feature**: Catalogs support an optional `instructions` field and are
  serialized with `functions` as a map plus `$defs`
  (`anyComponent`/`anyFunction`/`surfaceProperties`).
- **BREAKING**: Catalog entity names are validated against UAX #31
  identifier rules; `Catalog.themeSchema` is renamed to
  `surfacePropertiesSchema`; `A2uiClientError` supports `functionCallId`
  (mutually exclusive with `surfaceId`).

## 0.0.1-wip002

- **Feature**: Export `effect`.
- Initial version.
