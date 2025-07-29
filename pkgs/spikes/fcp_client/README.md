# Flutter Composition Protocol Client (fcp_client)

A Flutter package that implements the client-side responsibilities of the Flutter Composition Protocol (FCP). This package allows a Flutter application to render and manage a user interface dynamically from a JSON-based definition.

## Overview

The Flutter Composition Protocol (FCP) is a framework for building UIs where the structure, data, and events are defined by a server and interpreted by a client. This package provides the core client-side components to make this possible.

The core philosophy is a strict decoupling of:

- **The Catalog:** A contract defining the client's capabilities (widgets, properties, etc.).
- **The Layout:** The structure and arrangement of widgets.
- **The State:** The dynamic data that populates the layout.

This package provides the tools to parse these components and render a complete Flutter widget tree.

## Features

- **JSON to Widget Rendering:** Dynamically build a Flutter UI from a JSON `DynamicUIPacket`.
- **Extensible Catalog Registry:** Register your own custom Flutter widgets to be used in the dynamic UI.
- **Static Layout Engine:** Efficiently builds the widget tree from a non-recursive, flat adjacency list of nodes.
- **Event Handling:** A mechanism to capture and handle user interactions (e.g., button presses) and send them to a backend or state management layer.
- **Robust Error Handling:** Gracefully handles errors like missing widgets or cyclical layouts and displays a clear error UI instead of crashing.

## Getting Started

To use this package, add `fcp_client` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  fcp_client:
    path: <path_to_this_package> # Or use the pub.dev version when published
```

## Usage

Here is a simple example of how to use `FcpView` to render a UI. For a more complete, interactive example, see the `example/` directory.

```dart
import 'package:flutter/material.dart';
import 'package:fcp_client/fcp_client.dart';

void main() {
  runApp(const SimpleApp());
}

class SimpleApp extends StatelessWidget {
  const SimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Create a registry and register the widgets your UI will use.
    final registry = CatalogRegistry()
      ..register('Scaffold', (context, node, children) => Scaffold(body: children.first))
      ..register('Center', (context, node, children) => Center(child: children.first))
      ..register('Text', (context, node, children) {
        return Text(node.properties?['data'] as String? ?? 'Default Text');
      });

    // 2. Define the UI structure and data in a DynamicUIPacket.
    final uiPacket = DynamicUIPacket({
      'formatVersion': '1.0.0',
      'layout': {
        'root': 'root_scaffold',
        'nodes': [
          {'id': 'root_scaffold', 'type': 'Scaffold', 'properties': {'body': 'center_node'}},
          {'id': 'center_node', 'type': 'Center', 'properties': {'child': 'text_node'}},
          {'id': 'text_node', 'type': 'Text', 'properties': {'data': 'Hello from FCP!'}}
        ]
      },
      'state': {}
    });

    // 3. Use the FcpView widget to render the UI.
    return MaterialApp(
      home: FcpView(
        registry: registry,
        packet: uiPacket,
        onEvent: (payload) {
          print('Event received from ${payload.sourceNodeId}: ${payload.eventName}');
        },
      ),
    );
  }
}
```

## Documentation

For a deeper understanding of the protocol, implementation, and our development journey, please see the documents in the `docs/` directory:

- **[Flutter Composition Protocol.md](./docs/Flutter%20Composition%20Protocol.md):** The official specification for the FCP.
- **[FCP Implementation Plan.md](./docs/FCP%20Implementation%20Plan.md):** The technical plan and milestones for this package.
- **[JOURNEY.md](./docs/JOURNEY.md):** A detailed log of the development process, including challenges and learnings.
