# A2A Dart Package

## Overview

This package provides a Dart implementation of the A2A (Agent-to-Agent) protocol. It includes a client for interacting with A2A servers and a server framework for building A2A agents.

Here's the overview of the layout of this pacakge:

```
├── analysis_options.yaml
├── lib
│   ├── a2a_dart.dart
│   └── src
│       ├── client
│       │   ├── a2a_client.dart
│       │   ├── transport.dart
│       │   ├── http_transport.dart
│       │   └── sse_transport.dart
│       ├── core
│       │   ├── agent_card.dart
│       │   ├── message.dart
│       │   ├── task.dart
│       │   └── ... (other data models)
│       └── server
│           ├── a2a_server.dart (conditional export)
│           ├── request_handler.dart
│           ├── io
│           │   └── a2a_server.dart (native implementation)
│           └── web
│               └── a2a_server.dart (web stub)
├── pubspec.yaml
└── test
    ├── client
    │   └── a2a_client_test.dart
    ├── integration
    │   └── client_server_test.dart
    └── server
        └── a2a_server_test.dart
```

## Documentation and References

The design document in the `DESIGN.md` file provides an overview of the package's architecture and design decisions.

The high level overview of the package in the `README.md` file.

The A2A protocol specification is defined here: [A2A Protocol](https://a2a-protocol.org/latest/specification/).

## Client

`A2AClient` interacts with A2A servers. It supports RPC calls like `get_agent_card`, `create_task`, and `execute_task`. Communication is handled by a `Transport` interface, with `HttpTransport` for single requests and `SseTransport` for streaming.

## Server

`A2AServer` is a framework for building A2A agents on top of the `shelf` package. It uses a pipeline of `RequestHandler` instances to process requests, where each handler corresponds to an RPC method. The `handle` method returns a `HandlerResult`, which can be a `SingleResult` for one response or a `StreamResult` for a stream of responses.

## Data Models

The package includes Dart classes for A2A data structures (`AgentCard`, `Message`, `Task`, `SecurityScheme`). These are built with `freezed` and `json_serializable` to be immutable and support JSON serialization.
