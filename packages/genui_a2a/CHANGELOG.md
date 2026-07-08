# `genui_a2a` Changelog

## Next

- **BREAKING**: Migrated to A2UI protocol v1.0: the A2A extension URI is now
  `https://a2ui.org/a2a-extension/a2ui/v1.0` and client events use
  `version: "v1.0"` with optional `actionId`/`wantResponse`.
- **Feature**: Incoming `callFunction` and `actionResponse` data parts are
  routed to the message stream; added the `application/a2ui+json` MIME type
  constant.

## 0.10.0 (in progress)

- **BREAKING**: `A2uiAgentConnector.stream` now emits `package:a2ui_core`
  message types. Depend on `a2ui_core` directly to consume them.

## 0.9.0

- **BREAKING**: `A2uiAgentConnector` constructor now requires exactly one of `url` or `client` (#886).
- **Feature**: Export `A2AClient` (#886).

## 0.8.0

- **Fix**: Filter whitespace-only AI text responses (#759).
- **Refactor**: Rename `genui_a2ui` package to `genui_a2a` (#774).

## 0.7.0

- Updated version to match `genui` 0.7.0.

## 0.6.1

- **Refactor**: Switched to using a local implementation of the A2A client library, removing the dependency on `package:a2a` (#627).

## 0.6.0

- **BREAKING**: Updated to use `A2uiMessageProcessor` instead of `GenUiManager`.
- **BREAKING**: Updated to match `genui` 0.6.0 breaking changes.

## 0.5.1

- Homepage URL was updated.

## 0.5.0

- Initial published release.
