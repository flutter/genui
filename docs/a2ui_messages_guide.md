# A2UI Message Lifecycle

[A2UI](https://a2ui.org/) is a new protocol for servers to describe a user interface to a client by sending a stream of JSON messages. This document outlines the roles of the three core message types: `surfaceUpdate`, `DataModelUpdate`, and `beginRendering`.

## Core Concepts

Two principles guide the protocol's design:

1.  **Separation of Concerns:** The UI's **structure** (components) is managed independently from its **state** (data). This allows for efficient state updates without resending the UI definition.
2.  **Progressive Rendering:** The client can render the UI incrementally as it receives messages.

## Key Messages

### 1. `surfaceUpdate`

This message defines the structure of the UI. It contains a list of components, such as text fields, buttons, or layout containers, each with a unique ID. The client buffers these component definitions upon receipt.

### 2. `DataModelUpdate`

This message provides the state for the UI. It updates a client-side JSON data model that components can bind to. For example, a `DataModelUpdate` can specify the text for a label or the URL for an image.

### 3. `beginRendering`

This message signals the client that it is permitted to start rendering a UI surface. The timing of this message determines the rendering behavior.

## Rendering Lifecycle

The protocol supports two rendering strategies based on the timing of the `beginRendering` message.

### Strategy 1: Coordinated Initial Render

This strategy involves buffering messages to render a complete initial UI.

1.  **Stream Structure and State:** The server sends one or more `surfaceUpdate` and `DataModelUpdate` messages. The client buffers the components and data without rendering.
2.  **Send Render Signal:** The server sends the `beginRendering` message after the necessary UI information has been transmitted.
3.  **Render:** Upon receiving `beginRendering`, the client assembles and displays the complete UI from its buffer.

This approach prevents the user from seeing a partially loaded UI.

### Strategy 2: Progressive Streaming Render

This strategy renders UI components as they are received.

1.  **Send Render Signal Early:** The server sends the `beginRendering` message as one of the first messages for a surface.
2.  **Stream and Render:** The server then sends `surfaceUpdate` and `DataModelUpdate` messages. The client immediately renders or updates the UI as each message is received.

This approach can improve perceived performance for complex UIs.

### Dynamic Updates

After the initial render, the server can send additional `surfaceUpdate` or `DataModelUpdate` messages at any time to modify the UI in response to events.

## Future Considerations

Future versions of the A2UI specification may deprecate the `beginRendering` message. In such a scenario, `surfaceUpdate` messages would render immediately upon receipt, with a default root component ID assumed by the client. This would simplify the protocol by making the progressive streaming model the default behavior.