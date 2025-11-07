# `flutter_genui_a2ui` Package

## Overview

The `flutter_genui_a2ui` package provides an integration layer between Flutter applications using `flutter_genui` and an A2A (Agent-to-Agent) server implementing the A2UI Streaming UI Protocol. This package enables Flutter applications to receive dynamic UI updates from an AI agent and render them using the `flutter_genui` framework.

## Purpose

The primary purpose of this package is to facilitate the creation of generative UI experiences in Flutter by abstracting the complexities of A2A communication and A2UI message processing. It allows developers to focus on defining their widget catalog and integrating with AI models, while the package handles the real-time UI updates from the agent.

## Implementation Details

### `A2uiContentGenerator`

This class implements the `ContentGenerator` interface from `flutter_genui`. It acts as the main bridge between the `GenUiConversation` and the A2UI server. It uses an internal `A2uiAgentConnector` to handle the low-level A2A communication.

- **Constructor:** Takes `serverUrl` (the A2A server endpoint) and `genUiManager` (the `GenUiManager` instance from `flutter_genui`). An optional `A2AClient` can be provided for testing.
- **`generateContent` and `generateText`:** These methods are overridden to send user messages to the A2A server via the `A2uiAgentConnector`. UI updates are driven by the incoming A2UI stream, not direct return values from these methods.
- **`_handleUiEvent`:** This private method listens to `UiEvent`s dispatched by the `GenUiManager` (representing user interactions with the rendered UI) and translates them into A2A events to be sent back to the server.

### `A2uiAgentConnector`

This class is responsible for establishing and maintaining the WebSocket connection with the A2A server, sending A2A messages, and processing the incoming A2A stream events.

- **Constructor:** Takes the `url` of the A2A server. An optional `A2AClient` can be provided for testing.
- **`getAgentCard`:** Fetches metadata about the AI agent from the server.
- **`connectAndSend`:** Establishes a connection (if not already established), sends a user message to the A2A server, and processes the incoming A2A stream, extracting A2UI messages and forwarding them to the `A2uiContentGenerator`.
- **`sendEvent`:** Sends user interaction events (e.g., button clicks) back to the A2A server.
- **`_processA2uiMessages`:** An internal method to parse raw A2A data parts and convert them into `flutter_genui`'s `A2uiMessage` objects.

### `AgentCard`

A simple data class to hold metadata about the A2A agent, including its name, description, and version.

## File Layout

- `lib/flutter_genui_a2ui.dart`: Exports the public API of the package (`A2uiContentGenerator`, `A2uiAgentConnector`, `AgentCard`).
- `lib/src/a2ui_content_generator.dart`: Contains the `A2uiContentGenerator` implementation.
- `lib/src/a2ui_agent_connector.dart`: Contains the `A2uiAgentConnector` and `AgentCard` implementations.
- `test/a2ui_content_generator_test.dart`: Unit tests for `A2uiContentGenerator` and `A2uiAgentConnector`.
- `example/`: Contains a sample Flutter application demonstrating the usage of the `flutter_genui_a2ui` package.
