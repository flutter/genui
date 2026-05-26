# genui_express

Integrates A2UI Express compilation and local on-device AI engines with GenUI.

This package provides a transport layer that orchestrates offline Genkit model streams, maintains conversational session history, and compiles layout specifications using the A2UI Express layout DSL.

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  genui_express: ^0.1.0
```

Make sure you also have `package:genui` and `package:genkit` configured in your project.

## Usage

The core class in this package is `ExpressLocalTransport`, which coordinates Genkit stream generation and A2UI Express compilation.

### Code example

Below is an example demonstrating how to set up a chat session using `ExpressLocalTransport` and `SurfaceController`:

```dart
import 'package:genkit/genkit.dart' as genkit;
import 'package:genui/genui.dart';
import 'package:genui_express/genui_express.dart';

void setupChat() {
  // Initialize the local AI engine using Genkit
  final ai = genkit.Genkit(isDevEnv: false);

  // Reference the local inference model
  final model = genkit.modelRef('local/http-completion');

  // Define your component catalog
  final catalog = Catalog(
    systemPromptFragments: [],
    items: [],
  );

  // Set up the express local transport
  final transport = ExpressLocalTransport(
    ai: ai,
    model: model,
    catalog: catalog,
  );

  // Bind to the surface controller to handle UI rendering
  final controller = SurfaceController(catalogs: [catalog]);
  transport.incomingMessages.listen(controller.handleMessage);

  // Send a prompt to the local AI session
  transport.sendRequest(ChatMessage.user('Compare Kraft Boulders and Lone Mountain climbing sites.'));
}
```
