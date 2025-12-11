# `genui_a2ui` Package Context for AI Agents

## Purpose

This document provides context for AI agents making changes to the `genui_a2ui` package. This package acts as the bridge between the `genui` UI framework and any server implementing the [A2UI Streaming UI Protocol](https://a2ui.org).

## Key Concepts & Responsibilities

-   **`ContentGenerator` Interface:** `genui_a2ui` primarily provides an implementation of the `ContentGenerator` interface from the core `genui` package.
-   **A2A Communication:** All direct communication with the A2A server happens within this package, mainly in `A2uiAgentConnector` using the `package:a2a` client library.
-   **A2UI Message Parsing:** This package is responsible for taking the raw data from the A2A server and converting it into the structured `A2uiMessage` objects defined in `genui`.
-   **UI Event Submission:** It also handles sending UI interaction events from `genui` back to the A2A server.

## Core Classes to Understand

1.  **`A2uiContentGenerator`** (`lib/src/a2ui_content_generator.dart`):
    -   The main entry point for `GenUiConversation`.
    -   Orchestrates the connection and message flow.
    -   Listens to events from `A2uiAgentConnector` and forwards them on its own streams (`a2uiMessageStream`, `textResponseStream`, `errorStream`).
    -   Receives `UiEvent`s from `A2uiMessageProcessor` (via a listener setup in `GenUiConversation`) and passes them to `A2uiAgentConnector` to be sent to the server.

2.  **`A2uiAgentConnector`** (`lib/src/a2ui_agent_connector.dart`):
    -   Handles all WebSocket and JSON-RPC communication with the A2A server using `A2AClient`.
    -   Manages connection state, task ID, and context ID.
    -   `connectAndSend()`: Key method to send a `ChatMessage` and process the streamed response. This involves parsing `A2ADataPart` for A2UI messages.
    -   `sendEvent()`: Sends user interaction data back to the server.
    -   `_processA2uiMessages()`: Crucial for converting raw JSON data into `genui.A2uiMessage` objects.

3.  **`AgentCard`** (`lib/src/a2ui_agent_connector.dart`):
    -   Simple data class for agent metadata.

## Typical Modification Areas

-   **Protocol Changes:** Updates to how A2UI messages are parsed or how A2A messages are constructed in `A2uiAgentConnector`.
-   **Error Handling:** Improvements to error detection and reporting in either class.
-   **Connection Management:** Changes to how the WebSocket connection is handled in `A2uiAgentConnector`.
-   **Stream Management:** Modifications to the StreamControllers in `A2uiContentGenerator`.

## Testing

-   `test/a2ui_content_generator_test.dart` contains unit tests, primarily mocking the `A2AClient` to test the `A2uiAgentConnector` and `A2uiContentGenerator` logic in isolation.

## Dependencies

-   `genui`: Core UI framework.
-   `a2a`: A2A client library.
-   `logging`: For logging.
-   `uuid`: For message IDs.
