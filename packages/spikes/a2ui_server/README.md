# `a2ui_server`

The `a2ui_server` package is the server-side component of the GenUI framework. It leverages the [Genkit framework](https://genkit.dev/) to interact with a Large Language Model (LLM), dynamically generating UI definitions based on a conversation history. It exposes an A2A-compliant endpoint for clients to connect to.

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
   pnpm run build-and-run
   ```

3. This will start the A2A server on http://localhost:10002.

## Logging

This package uses `pino` for structured logging. Logging is disabled by default. To enable it, set the `LOG_LEVEL` environment variable when running the server.

- To enable `info` level logging:

  ```bash
  LOG_LEVEL=info pnpm run build-and-run
  ```

- To enable `debug` level logging for more verbose output:

  ```bash
  LOG_LEVEL=debug pnpm run build-and-run
  ```

Supported log levels are: `fatal`, `error`, `warn`, `info`, `debug`, and `trace`. In development, logs are automatically formatted for readability.
