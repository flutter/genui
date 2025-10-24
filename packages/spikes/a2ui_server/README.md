# `a2ui_server`

The `a2ui_server` package is the server-side component of the GenUI framework. It leverages the [Genkit framework](https://genkit.dev/) to interact with a Large Language Model (LLM), dynamically generating UI definitions based on a conversation history and a client-provided widget catalog. It is designed to be a stateless, scalable, and secure backend for any GenUI-compatible client.

## Getting Started

### Prerequisites

- Node.js
- pnpm

### Installation

1. Navigate to the `packages/a2ui_server` directory.
2. Install the dependencies:

   ```bash
   pnpm install
   ```

### Running the Server

1. You will need to configure your environment with the necessary API keys for the desired AI provider (e.g., Google AI).
2. To run the server in development mode with hot-reloading, use the following command:

   ```bash
   pnpm run genkit:dev
   ```

3. This will start the Genkit development UI, where you can inspect flows and interact with the server.

## Logging

This package uses `pino` for structured logging. Logging is disabled by default. To enable it, set the `LOG_LEVEL` environment variable when running the server.

- To enable `info` level logging:

  ```bash
  LOG_LEVEL=info pnpm run genkit:dev
  ```

- To enable `debug` level logging for more verbose output:

  ```bash
  LOG_LEVEL=debug pnpm run genkit:dev
  ```

Supported log levels are: `fatal`, `error`, `warn`, `info`, `debug`, and `trace`. In development, logs are automatically formatted for readability.

## API

The server exposes one primary HTTP endpoint, which corresponds to a Genkit flow.

### `POST /generateUi` (Streaming)

This endpoint generates UI updates in real-time for a given conversation. It takes the current conversation state and generates the next UI to be displayed, streaming UI modification messages as they are produced by the LLM.

- **Request Body**: The request body must match the `generateUiRequestSchema` defined in `src/schemas.ts`.

  ```json
  {
    "catalog": {
      // A valid JSON schema describing the client's widget catalog
    },
    "conversation": [
      {
        "role": "user",
        "parts": [{ "type": "text", "text": "Show me a login form." }]
      }
      // ... more messages
    ]
  }
  ```

- **Response Body**: A stream of JSON objects representing the desired UI modifications, transformed from the raw output of the LLM. The client is responsible for interpreting these streamed messages and updating its UI accordingly. The final text response from the model is ignored.

- **Example Streamed Chunks**:

  When a UI surface needs to be added or updated, the server sends two messages in sequence. The first, `surfaceUpdate`, provides the component definitions.

  ```json
  {
    "surfaceUpdate": {
      "surfaceId": "some-surface",
      "components": [
        { "id": "widget1", "widget": { "type": "text", "text": "Hello" } }
      ]
    }
  }
  ```

  The second message, `beginRendering`, signals to the client that it should now render the new UI tree.

  ```json
  {
    "beginRendering": {
      "surfaceId": "some-surface",
      "root": "widget1"
    }
  }
  ```

  When a UI surface needs to be removed, the server sends a `deleteSurface` message.

  ```json
  {
    "deleteSurface": {
      "surfaceId": "some-surface"
    }
  }
  ```
