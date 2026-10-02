# Migration Guide: 0.10.x to 0.11.0

`package:genui` now depends on `a2ui_core` 0.2.2. Most apps need no code
changes. You need to change code only if you **depend on `a2ui_core` yourself,
implement a custom `Transport`, or construct or parse A2UI messages directly**.
Every app should check its agent's output against the stricter validation below:
messages that 0.10.x rendered can now be rejected.

## What you have to change

### Raise your `a2ui_core` constraint

If your app depends on `a2ui_core`, raise the constraint to `^0.2.2`.

### `A2uiMessage` is now `AgentToRendererMessage`

`a2ui_core` renamed its message type. The subtypes (`CreateSurfaceMessage`,
`UpdateComponentsMessage`, `UpdateDataModelMessage`, `DeleteSurfaceMessage`)
keep their names.

```dart
// Before
Stream<A2uiMessage> get incomingMessages => _messages.stream;
final message = A2uiMessage.fromJson(json);

// After
Stream<AgentToRendererMessage> get incomingMessages => _messages.stream;
final message = AgentToRendererMessage.fromJson(json);
```

The new name appears in `A2uiMessageSink.handleMessage` (and so
`SurfaceController.handleMessage`), `Transport.incomingMessages`,
`A2uiTransportAdapter.addMessage`, `A2uiMessageEvent.message` and, in
`genui_a2a`, `A2uiAgentConnector.stream`.

## Behavior you may notice

- **Messages are validated before they are applied.** A message with a
  component that does not match its catalog's schema is rejected whole: none of
  its components render. The agent still receives a `VALIDATION_FAILED` error
  naming the component. An update that omits `component` is applied as
  before.
- **More messages are rejected**, each reported as `VALIDATION_FAILED`:
  duplicate component ids in one message; component references that form a
  cycle, through `child` or `children` (these used to crash the build with a
  stack overflow); a component chain or a message nested more than 50 levels
  deep; function calls nested more than 5 deep; and any `path` string that is
  not a valid data path, including inside `updateDataModel` values.
- **A surface that names a catalog the controller does not hold renders
  nothing**, where it used to show a fallback widget, and each component update
  sent to it is reported. Data model updates to it still apply.
- **A `DataModel` write below a primitive value throws `A2uiDataError`**, such
  as writing `/a/b` when `/a` holds a string. It used to be ignored. An input
  widget bound to such a path throws from its change handler when the user
  edits it.
- **`DataModel` subscribers no longer fire when a write leaves their value
  unchanged.**
- **Deleting a list index past its end leaves the list unchanged**, where it
  used to pad the list with `null`.
