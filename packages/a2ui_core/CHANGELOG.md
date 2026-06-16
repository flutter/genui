# `a2ui_core` Changelog

## 0.0.1-wip002

- **Feature**: Re-export preact_signals `effect` and `Effect`.
- **Fix**: `DataModel.set` deep-copies map/list payloads so later nested
  writes work even when callers pass const literals.
- **Behavior**: `DataPath` no longer interprets RFC 6901 `~0`/`~1`
  escapes; paths split on `/` only, matching the TypeScript reference
  implementation (see A2UI#1499 tracking spec clarification).

## 0.0.1-dev002

- Initial version.
