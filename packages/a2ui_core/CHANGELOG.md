# `a2ui_core` Changelog

## 0.0.1-wip002

- **Feature**: Export `effect` and `Effect`.
- **Fix**: `DataModel.set` copies map and list values so later writes into
  nested paths succeed.
- **Behavior**: `DataPath` no longer interprets `~0`/`~1` escapes; paths
  split on `/` only.

## 0.0.1-dev002

- Initial version.
