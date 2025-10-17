# Project Overview

This project, `a2ui_client`, is a Flutter package that acts as a client for the A2UI (Generative UI Language Framework) Streaming UI Protocol. Its primary purpose is to enable the creation of server-driven user interfaces in a Flutter application. A backend service (potentially an LLM) can generate a UI definition in a simple, "LLM-friendly", line-delimited JSON (JSONL) format, which is then streamed to the client. The client interprets this stream and renders a native Flutter UI. This allows for highly dynamic UIs that can be updated without requiring a new client application release.

The framework is built on a few core concepts:

- **Streaming UI Definition (JSONL):** The UI is described by a stream of small, atomic JSON messages, allowing the UI to be built and updated incrementally.
- **Component Tree:** The UI is represented as a tree of abstract `Component`s, each with a unique `id` and properties.
- **Decoupled Data Model:** The application's state is held in a separate, JSON-like data model. Components can bind to this data using a simple path syntax.
- **Extensible Widget Registry:** The client uses a `WidgetRegistry` to map abstract component types to concrete Flutter widget implementations, making the renderer fully extensible.

The project uses the `freezed` package for code generation of data models and `json_serializable` for JSON serialization/deserialization.

## Architecture

The client's architecture is centered around a few key classes:

- **`A2uiInterpreter`**: The core of the client. It consumes the JSONL stream, parses messages, and manages the state of the component tree and the data model.
- **`A2uiView`**: The main Flutter widget that listens to the `A2uiInterpreter` and rebuilds the UI when the state changes.
- **`WidgetRegistry`**: An extension point where developers register builder functions to map component definitions from the stream to actual Flutter widgets.
- **`A2uiAgentConnector`**: Connects to a live A2UI Agent endpoint, handles the A2A protocol, and provides the stream of A2UI protocol lines.
- **`ComponentPropertiesVisitor`**: A visitor class that resolves component properties, handling data bindings from the data model.

The data flows in one direction: from the server stream (either from a manual source or the `A2uiAgentConnector`), through the `A2uiInterpreter`, to the `A2uiView`, which uses the `WidgetRegistry` to build and render the final Flutter widget tree.

The example application uses the `provider` package for state management. An `AgentState` class, which is a `ChangeNotifier`, holds the `A2uiAgentConnector`, `A2uiInterpreter`, and `AgentCard`. This state is provided to the widget tree using `ChangeNotifierProvider`, and widgets that need to access the state can do so using `context.watch<AgentState>()`.

For more detailed information on the architecture and implementation, see the `IMPLEMENTATION.md` file.

## Building and Running

This is a Dart package, so there isn't a main application to run directly. However, the `example` directory contains a complete Flutter application that demonstrates how to use the `a2ui_client` package.

To run the example application:

1.  Navigate to the `example` directory:

    ```bash
    cd example
    ```

2.  Get the dependencies:

    ```bash
    flutter pub get
    ```

3.  Run the code generator to generate the necessary `freezed` and `json_serializable` files:

    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  Run the application:

    ```bash
    flutter run
    ```

## Development Conventions

### Code Style

The project follows the official Dart style guide and uses the `dart_flutter_team_lints` package for linting. The linting rules are defined in the `analysis_options.yaml` file.

### Testing

The project uses `flutter_test` for testing. Tests are located in the `test` directory. To run the tests, use the following command from the root of the package:

```bash
flutter test
```

The tests use `mockito` for generating mock classes.

### A2UI Protocol

The A2UI protocol is defined in the `a2ui_schema.json` file. It is a JSONL-based protocol where each line is a JSON object representing a message. The main message types are:

- `streamHeader`: The first message in any stream, identifying the protocol and version.
- `componentUpdate`: Adds or updates one or more components in the UI tree.
- `dataModelUpdate`: Adds or updates a part of the data model at a given path.
- `beginRendering`: Signals to the client that it has enough information to perform the initial render.

The `IMPLEMENTATION.md` file contains a detailed explanation of the protocol and the client's architecture.
