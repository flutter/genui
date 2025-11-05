# A2A Dart Library Implementation Plan

This document outlines the phased implementation plan for the `a2a_dart` library.

## Journal

**Phase 1: Project Setup and Core Models**

- **Actions:**
  - Initialized a pure Dart project.
  - Added all necessary dependencies for the project.
  - Created all core data models in `lib/src/core` using `freezed` and `json_serializable`.
  - Wrote a full suite of unit tests for the data models to ensure correct JSON serialization and deserialization.
- **Learnings:**
  - The interaction between `freezed` and `json_serializable` can be complex, especially with nested objects. It is crucial to have `explicit_to_json: true` in `build.yaml` to ensure that `toJson()` is called on all nested objects.
  - The `@JsonKey` annotation can be used to map Dart fields to JSON fields with names that are reserved keywords in Dart (e.g., `in_` to `in`).

**Phase 2: Client Implementation**

- **Actions:**
  - Defined the `Transport` interface and created `HttpTransport` and `SseTransport` implementations.
  - Implemented the `A2AClient` with methods for all core A2A RPC calls.
  - Created an `A2AHandler` pipeline for extensible client behavior.
  - Wrote a full suite of unit tests for the client, mocking the transport layer to ensure correct behavior.
- **Learnings:**
  - When using `json_serializable`, it is important to be aware of the `fieldRename` option in `build.yaml`. By default, it is `camelCase`, so JSON keys are expected to be in that format. This can be changed to `snake_case` if needed.
  - When testing streams, the `emitsInOrder` matcher is very useful for verifying a sequence of events.

**Phase 3: Server Framework**

- **Actions:**
  - Implemented the `A2AServer` class using the `shelf` and `shelf_router` packages.
  - Defined a `RequestHandler` interface to create a modular and extensible handler system.
  - Implemented a `TaskManager` to manage the lifecycle of A2A tasks.
  - Wrote a full suite of unit tests for all server components, including the `A2AServer`, `TaskManager`, and `CreateTaskHandler`.
- **Learnings:**
  - The `shelf` package provides a simple and effective way to build modular web servers in Dart.
  - Dependency conflicts can be tricky to resolve. It is important to pay attention to the version constraints of all dependencies.

## Phase 1: Project Setup and Core Models

- [x] Initialize a pure Dart project in the `a2a_dart` directory.
- [x] Add dependencies: `http`, `freezed`, `json_serializable`, `logging`, `sse_client`.
- [x] Create the core data models in `lib/src/core` based on the A2A specification, using `freezed` for immutability and `json_serializable` for JSON conversion.
- [x] Write unit tests for the data models, ensuring correct JSON serialization and deserialization.

## Phase 2: Client Implementation

- [x] Define the `Transport` interface and create an `HttpTransport` implementation for request-response.
- [x] Create an `SseTransport` implementation for streaming responses.
- [x] Implement the `A2AClient` class with methods for all A2A RPC calls, including a `messageStream` method that returns a `Stream`.
- [x] Implement a middleware pipeline for the client.
- [x] Write unit tests for the `A2AClient`, `HttpTransport`, and `SseTransport`.

## Phase 3: Server Framework

- [x] Implement the `A2AServer` class.
- [x] Define the `RequestHandler` interface.
- [x] Implement the `TaskManager` for managing task state.
- [x] Write unit tests for the server components.

## Phase 4: Integration and Documentation

- [ ] Write integration tests for the client and server.
- [ ] Add comprehensive DartDoc comments to all public APIs.
- [ ] Create a detailed `README.md` with usage examples.
- [ ] Create a `GEMINI.md` file describing the package.

## General Tasks for Each Phase

After completing each phase, the following tasks should be performed:

- [ ] Create/modify unit tests for the code added or modified in this phase.
- [ ] Run `dart fix --apply` to clean up the code.
- [ ] Run `dart analyze` and fix any issues.
- [ ] Run all tests to ensure they pass.
- [ ] Run `dart format .` to ensure correct formatting.
- [ ] Update this `IMPLEMENTATION.md` file with the current state.
- [ ] Commit the changes with a descriptive commit message.
