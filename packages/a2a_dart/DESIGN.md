# A2A Dart Library Design Document

## 1. Overview

This document outlines the design for a pure Dart implementation of the Agent2Agent (A2A) protocol. The `a2a_dart` library provides both client and server components for A2A communication. The client is platform-independent and can be used in web applications, while the server is designed for native platforms that support `dart:io`.

The primary goal is to create a library that is:

- **Comprehensive**: Implements the full A2A specification.
- **Idiomatic**: Feels natural to Dart and Flutter developers.
- **Type-Safe**: Leverages Dart's strong type system to prevent errors.
- **Extensible**: Allows for future expansion and customization.

## 2. Goals and Non-Goals

### Goals

- Provide a type-safe, idiomatic Dart implementation of the A2A protocol.
- Support the full A2A specification, including all data models and RPC methods.
- Offer a clear and easy-to-use client API for interacting with A2A agents.
- Provide a flexible and extensible server framework for building A2A agents in Dart.
- Adhere to Dart and Flutter best practices, including null safety, effective asynchronous programming, and clean architecture.

### Non-Goals

- **Transports**: Implement transport protocols other than JSON-RPC and SSE over HTTP. gRPC and REST transports are out of scope for the initial version.
- **Push Notifications**: The server-side push notification mechanism will not be implemented initially. The client will support sending the configuration, but the server will not act on it.
- **Agent Framework**: Provide a full-fledged agent framework with built-in AI capabilities. This library focuses on the communication protocol.
- **Extensions**: Implement any of the optional extensions to the A2A protocol in the initial version.

## 3. Implemented A2A Features

The `a2a_dart` library implements the following features from the A2A specification:

### Core Concepts

- **Client & Server**: Foundational components for initiating and responding to A2A requests.
- **Agent Card**: Full implementation for agent discovery and capability advertisement.
- **Task**: State management for all agent operations.
- **Message**: The primary object for communication turns.
- **Part**: Support for `TextPart`, `FilePart`, and `DataPart` to enable rich content exchange.
- **Artifact**: Handling for agent-generated outputs.
- **Context**: Grouping related tasks.

### Transport Protocols

- **JSON-RPC 2.0**: The primary transport protocol for all RPC methods over HTTP/S.
- **Server-Sent Events (SSE)**: For real-time, streaming updates from the server to the client (`message/stream` and `tasks/resubscribe`).

### Data Models

- A complete, type-safe implementation of all data objects defined in the specification, including:
  - `Task`, `TaskStatus`, `TaskState`
  - `Message`, `Part` (and its variants)
  - `AgentCard` (and all nested objects like `AgentSkill`, `AgentProvider`, etc.)
  - `Artifact`
  - `PushNotificationConfig` (client-side only)
  - All JSON-RPC request, response, and error structures.

### RPC Methods

- The library provides client methods and server-side handlers for the following A2A RPC methods:
  - `get_agent_card` (via HTTP GET)
  - `create_task`
  - `message/stream`
  - `execute_task`

### Authentication

- The library will be designed to work with standard HTTP authentication mechanisms (e.g., Bearer Token, API Key) by providing hooks (middleware) for adding authentication headers to client requests.

## 4. Architecture

The `a2a_dart` library is structured with a single public entry point, `lib/a2a_dart.dart`, which exports the core, client, and server APIs. The internal structure is organized as follows:

- **`lib/src`**: Contains the private implementation of the library.
  - **`core`**: Contains the platform-independent data models and types defined in the A2A specification.
  - **`client`**: Provides the `A2AClient` class and transport implementations (`HttpTransport`, `SseTransport`).
  - **`server`**: Offers a framework for building A2A agents. It uses a conditional export (`a2a_server.dart`) to provide a native implementation (`io/a2a_server.dart`) and a web stub (`web/a2a_server.dart`).

```mermaid
graph TD
    subgraph Public API
        A[lib/a2a_dart.dart]
    end

    subgraph "Implementation (lib/src)"
        B[Core]
        C[Client]
        D[Server]
    end

    A --> B
    A --> C
    A --> D

    B --> B1[Data Models]

    C --> C1[A2AClient]
    C --> C2[Transport]
    C2 --> C2a[HttpTransport]
    C2 --> C2b[SseTransport]

    D --> D1[a2a_server.dart (conditional export)]
    D1 --> D1a[io/a2a_server.dart]
    D1 --> D1b[web/a2a_server.dart]
    D --> D2[RequestHandler]
```

## 4. Data Models

All data models from the A2A specification will be implemented as immutable Dart classes. To reduce boilerplate and ensure correctness, we will use the `json_serializable` and `freezed` packages for JSON serialization and value equality.

- **Immutability**: All model classes will be immutable.
- **JSON Serialization**: Each class will have `fromJson` and `toJson` methods.
- **Null Safety**: All fields will be null-safe.

Example `AgentCard` model:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_card.freezed.dart';
part 'agent_card.g.dart';

@freezed
class AgentCard with _$AgentCard {
  const factory AgentCard({
    required String protocolVersion,
    required String name,
    required String description,
    required String url,
    // ... other fields
  }) = _AgentCard;

  factory AgentCard.fromJson(Map<String, dynamic> json) => _$AgentCardFromJson(json);
}
```

## 5. Client API

The client API will be centered around the `A2AClient` class. This class will provide methods for each of the A2A RPC calls, such as `sendMessage`, `getTask`, and `cancelTask`.

- **Asynchronous**: All API methods will be asynchronous, returning `Future`s.
- **Transport Agnostic**: The `A2AClient` delegates the actual HTTP communication to a `Transport` interface. This allows for different transport implementations, with `HttpTransport` providing basic request-response and `SseTransport` extending it for streaming.

Example `A2AClient` usage:

```dart
final log = Logger('MyClient');
final client = A2AClient(
  url: 'https://example.com/a2a',
  transport: SseTransport(url: 'https://example.com/a2a', log: log),
);

// Create a task
final task = await client.createTask(Message(
  messageId: '1',
  role: Role.user,
  parts: [Part.text(text: 'Hello, agent!')],
));

// Execute the task and get a stream of events
final stream = client.executeTask(task.id);
await for (final event in stream) {
  // process events
}
```

## 6. Server Framework

The server framework will provide the building blocks for creating A2A-compliant agents in Dart.

- **`A2AServer`**: A top-level class that listens for incoming HTTP requests. It is conditionally exported to support both native and web platforms. On native, it uses `dart:io` to create an HTTP server. On the web, it throws an `UnsupportedError` if instantiated.
- **`RequestHandler`**: An interface for handling specific A2A methods. Developers will implement this interface to define their agent's behavior. The `handle` method returns a `HandlerResult` which can be a `SingleResult` for a single response or a `StreamResult` for a streaming response.
- **`TaskManager`**: A class responsible for managing the lifecycle of tasks.

## 7. Error Handling

Errors will be handled using a combination of exceptions and a `Result` type. Network and transport-level errors will throw exceptions, while A2A-specific errors will be returned as part of a `Result` object, allowing for more granular error handling.

## 8. Dependencies

- `http`: For making HTTP requests.
- `freezed`: For immutable data classes.
- `json_serializable`: For JSON serialization.
- `shelf`: For building the server.
- `shelf_router`: For routing requests on the server.
- `uuid`: For generating unique IDs.

## 9. Testing

The library will have a comprehensive suite of unit and integration tests.

- **Unit Tests**: Will cover individual classes and methods in isolation.
- **Integration Tests**: Will test the client and server components together, as well as against a known-good A2A implementation.

## 10. Documentation

All public APIs will be thoroughly documented with DartDoc comments. The package will also include a comprehensive `README.md` and example usage.
