# genui

A Flutter package for building dynamic, conversational user interfaces powered by generative AI models.

`genui` allows you to create applications where the UI is not static or predefined, but is instead constructed by an AI in real-time based on a conversation with the user. This enables highly flexible, context-aware, and interactive user experiences.

This package provides the core functionality for GenUI. For concrete implementations, see the `genui_firebase_ai` package (for Firebase AI) or the `genui_a2ui` package (for a generic A2UI server).

## Features

- **Dynamic UI Generation**: Render Flutter UIs from structured data returned by a generative AI.
- **Simplified Conversation Flow**: A high-level `GenUiConversation` facade manages the interaction loop with the AI.
- **Customizable Widget Catalog**: Define a "vocabulary" of Flutter widgets that the AI can use to build the interface.
- **Extensible Content Generator**: Abstract interface for connecting to different AI model backends.
- **Event Handling**: Capture user interactions (button clicks, text input), update a client-side data model, and send the state back to the AI as context for the next turn in the conversation.
- **Reactive UI**: Widgets automatically rebuild when the data they are bound to changes in the data model.

## Core Concepts

The package is built around the following main components:

1.  **`GenUiConversation`**: The primary facade and entry point for the package. It encapsulates the `GenUiManager` and `ContentGenerator`, manages the conversation history, and orchestrates the entire generative UI process.

2.  **`Catalog`**: A collection of `CatalogItem`s that defines the set of widgets the AI is allowed to use. Each `CatalogItem` specifies a widget's name (for the AI to reference), a data schema for its properties, and a builder function to render the Flutter widget.

3.  **`DataModel`**: A centralized, observable store for all dynamic UI state. Widgets are "bound" to data in this model. When data changes, only the widgets that depend on that specific piece of data are rebuilt.

4.  **`ContentGenerator`**: An interface for communicating with a generative AI model. This interface uses streams to send `A2uiMessage` commands, text responses, and errors back to the `GenUiConversation`.

5.  **`A2uiMessage`**: A message sent from the AI (via the `ContentGenerator`) to the UI, instructing it to perform actions like `beginRendering`, `surfaceUpdate`, `dataModelUpdate`, or `deleteSurface`.

## How It Works

The `GenUiConversation` manages the interaction cycle:

1. **User Input**: The user provides a prompt (e.g., through a text field). The app calls `genUiConversation.sendRequest()`.
2. **AI Invocation**: The `GenUiConversation` adds the user's message to its internal conversation history and calls `contentGenerator.sendRequest()`.
3. **AI Response**: The `ContentGenerator` interacts with the AI model. The AI, guided by the widget schemas, sends back responses.
4. **Stream Handling**: The `ContentGenerator` emits `A2uiMessage`s, text responses, or errors on its streams.
5. **UI State Update**: `GenUiConversation` listens to these streams. `A2uiMessage`s are passed to `GenUiManager.handleMessage()`, which updates the UI state and `DataModel`.
6. **UI Rendering**: The `GenUiManager` broadcasts an update, and any `GenUiSurface` widgets listening for that surface ID will rebuild. Widgets are bound to the `DataModel`, so they update automatically when their data changes.
7. **Callbacks**: Text responses and errors trigger the `onTextResponse` and `onError` callbacks on `GenUiConversation`.
8. **User Interaction**: The user interacts with the newly generated UI (e.g., by typing in a text field). This interaction directly updates the `DataModel`. If the interaction is an action (like a button click), the `GenUiSurface` captures the event and forwards it to the `GenUiConversation`'s `GenUiManager`, which automatically creates a new `UserMessage` containing the current state of the data model and restarts the cycle.

```mermaid
graph TD
    subgraph "User"
        UserInput("Provide Prompt")
        UserInteraction("Interact with UI")
    end

    subgraph "GenUI Framework"
        GenUiConversation("GenUiConversation")
        ContentGenerator("ContentGenerator")
        GenUiManager("GenUiManager")
        GenUiSurface("GenUiSurface")
    end

    UserInput -- "calls sendRequest()" --> GenUiConversation;
    GenUiConversation -- "sends prompt" --> ContentGenerator;
    ContentGenerator -- "returns A2UI messages" --> GenUiConversation;
    GenUiConversation -- "handles messages" --> GenUiManager;
    GenUiManager -- "notifies of updates" --> GenUiSurface;
    GenUiSurface -- "renders UI" --> UserInteraction;
    UserInteraction -- "creates event" --> GenUiSurface;
    GenUiSurface -- "sends event to host" --> GenUiManager;
    GenUiManager -- "sends user input to" --> GenUiConversation;
```

See [DESIGN.md](./DESIGN.md) for more detailed information about the design.

## Getting Started with `genui`

This guidance explains how to quickly get started with the
[`genui`](https://pub.dev/packages/genui) package.

### 1. Add `genui` to your app

Use the following instructions to add `genui` to your Flutter app. The
code examples show how to perform the instructions on a brand new app created by
running `flutter create`.

### 2. Configure your agent provider

`genui` can connect to a variety of agent providers. Choose the section
below for your preferred provider.

#### Configure Firebase AI Logic

To use the built-in `FirebaseAiContentGenerator` to connect to Gemini via Firebase AI
Logic, follow these instructions:

1. [Create a new Firebase project](https://support.google.com/appsheet/answer/10104995)
   using the Firebase Console.
2. [Enable the Gemini API](https://firebase.google.com/docs/gemini-in-firebase/set-up-gemini)
   for that project.
3. Follow the first three steps in
   [Firebase's Flutter Setup guide](https://firebase.google.com/docs/flutter/setup)
   to add Firebase to your app.
4. In `pubspec.yaml`, add `genui` and `genui_firebase_ai` to the
   `dependencies` section.

   ```yaml
   dependencies:
     # ...
     genui: 0.5.0
     genui_firebase_ai: 0.5.0
   ```

5. In your app's `main` method, ensure that the widget bindings are initialized,
   and then initialize Firebase.

   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
     runApp(const MyApp());
   }
   ```

#### Configure another agent provider

To use `genui` with another agent provider, you need to follow that
provider's instructions to configure your app, and then create your own subclass
of `ContentGenerator` to connect to that provider. Use `FirebaseAiContentGenerator` or
`A2uiContentGenerator` (from the `genui_a2ui` package) as examples
of how to do so.

### 3. Create the connection to an agent

If you build your Flutter project for iOS or macOS, add this key to your
`{ios,macos}/Runner/*.entitlements` file(s) to enable outbound network
requests:

```xml
<dict>
...
<key>com.apple.security.network.client</key>
<true/>
</dict>
```

Next, use the following instructions to connect your app to your chosen agent
provider.

1. Create a `GenUiManager`, and provide it with the catalog of widgets you want
   to make available to the agent.
2. Create a `ContentGenerator`, and provide it with a system instruction and a set of
   tools (functions you want the agent to be able to invoke). You should always
   include those provided by `GenUiManager`, but feel free to include others.
3. Create a `GenUiConversation` using the instances of `ContentGenerator` and `GenUiManager`. Your
   app will primarily interact with this object to get things done.

   For example:

   ```dart
   class _MyHomePageState extends State<MyHomePage> {
     late final GenUiManager _genUiManager;
     late final GenUiConversation _genUiConversation;

     @override
     void initState() {
       super.initState();

       // Create a GenUiManager with a widget catalog.
       // The CoreCatalogItems contain basic widgets for text, markdown, and images.
       _genUiManager = GenUiManager(catalog: CoreCatalogItems.asCatalog());

       // Create a ContentGenerator to communicate with the LLM.
       // Provide system instructions and the tools from the GenUiManager.
       final contentGenerator = FirebaseAiContentGenerator(
         systemInstruction: '''
           You are an expert in creating funny riddles. Every time I give you a word,
           you should generate UI that displays one new riddle related to that word.
           Each riddle should have both a question and an answer.
           ''',
         tools: _genUiManager.getTools(),
       );

       // Create the GenUiConversation to orchestrate everything.
       _genUiConversation = GenUiConversation(
         genUiManager: _genUiManager,
         contentGenerator: contentGenerator,
         onSurfaceAdded: _onSurfaceAdded, // Added in the next step.
         onSurfaceDeleted: _onSurfaceDeleted, // Added in the next step.
       );
     }

     @override
     void dispose() {
       _textController.dispose();
       _genUiConversation.dispose();

       super.dispose();
     }
   }
   ```

### 4. Send messages and display the agent's responses

Send a message to the agent using the `sendRequest` method in the `GenUiConversation`
class.

To receive and display generated UI:

1. Use `GenUiConversation`'s callbacks to track the addition and removal of UI surfaces as
   they are generated. These events include a "surface ID" for each surface.
2. Build a `GenUiSurface` widget for each active surface using the surface IDs
   received in the previous step.

   For example:

   ```dart
   class _MyHomePageState extends State<MyHomePage> {

     // ...

     final _textController = TextEditingController();
     final _surfaceIds = <String>[];

     // Send a message containing the user's text to the agent.
     void _sendMessage(String text) {
       if (text.trim().isEmpty) return;
       _genUiConversation.sendRequest(UserMessage.text(text));
     }

     // A callback invoked by the [GenUiConversation] when a new UI surface is generated.
     // Here, the ID is stored so the build method can create a GenUiSurface to
     // display it.
     void _onSurfaceAdded(SurfaceAdded update) {
       setState(() {
         _surfaceIds.add(update.surfaceId);
       });
     }

     // A callback invoked by GenUiConversation when a UI surface is removed.
     void _onSurfaceDeleted(SurfaceRemoved update) {
       setState(() {
         _surfaceIds.remove(update.surfaceId);
       });
     }

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(
           backgroundColor: Theme.of(context).colorScheme.inversePrimary,
           title: Text(widget.title),
         ),
         body: Column(
           children: [
             Expanded(
               child: ListView.builder(
                 itemCount: _surfaceIds.length,
                 itemBuilder: (context, index) {
                   // For each surface, create a GenUiSurface to display it.
                   final id = _surfaceIds[index];
                   return GenUiSurface(host: _genUiConversation.host, surfaceId: id);
                 },
               ),
             ),
             SafeArea(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
                 child: Row(
                   children: [
                     Expanded(
                       child: TextField(
                         controller: _textController,
                         decoration: const InputDecoration(
                           hintText: 'Enter a message',
                         ),
                       ),
                     ),
                     const SizedBox(width: 16),
                     ElevatedButton(
                       onPressed: () {
                         // Send the user's text to the agent.
                         _sendMessage(_textController.text);
                         _textController.clear();
                       },
                       child: const Text('Send'),
                     ),
                   ],
                 ),
               ),
             ),
           ],
         ),
       );
     }
   }
   ```

### 5. [Optional] Add your own widgets to the catalog

In addition to using the catalog of widgets in `CoreCatalogItems`, you can
create custom widgets for the agent to generate. Use the following
instructions.

#### Import `json_schema_builder`

Add the `json_schema_builder` package as a dependency in `pubspec.yaml`. Use the
same commit reference as the one for `genui`.

```yaml
dependencies:
  # ...
  json_schema_builder:
    git:
      url: https://github.com/flutter/genui.git
      path: packages/json_schema_builder

```

#### Create the new widget's schema

Each catalog item needs a schema that defines the data required to populate it.
Using the `json_schema_builder` package, define one for the new widget.

```dart
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

final _schema = S.object(
  properties: {
    'question': S.string(description: 'The question part of a riddle.'),
    'answer': S.string(description: 'The answer part of a riddle.'),
  },
  required: ['question', 'answer'],
);
```

#### Create a `CatalogItem`

Each `CatalogItem` represents a type of widget that the agent is allowed to
generate. To do that, combines a name, a schema, and a builder function that
produces the widgets that compose the generated UI.

```dart
final riddleCard = CatalogItem(
  name: 'RiddleCard',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final json = data as Map<String, Object?>;
        final question = json['question'] as String;
        final answer = json['answer'] as String;

        return Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(border: Border.all()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8.0),
              Text(answer, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        );
      },
);
```

#### Add the `CatalogItem` to the catalog

Include your catalog items when instantiating `GenUiManager`.

```dart
_genUiManager = GenUiManager(
  catalog: CoreCatalogItems.asCatalog().copyWith([riddleCard]),
);
```

#### Update the system instruction to use the new widget

In order to make sure the agent knows to use your new widget, use the system
instruction to explicitly tell it how and when to do so. Provide the name from
the CatalogItem when you do.

```dart
final contentGenerator = FirebaseAiContentGenerator(
  systemInstruction: '''
      You are an expert in creating funny riddles. Every time I give you a word,
      you should generate a RiddleCard that displays one new riddle related to that word.
      Each riddle should have both a question and an answer.
      ''',
  tools: _genUiManager.getTools(),
);
```

### Data Model and Data Binding

A core concept in `genui` is the **`DataModel`**, a centralized, observable store for all dynamic UI state. Instead of widgets managing their own state, their state is stored in the `DataModel`.

Widgets are "bound" to data in this model. When data in the model changes, only the widgets that depend on that specific piece of data are rebuilt. This is achieved through a `DataContext` object that is passed to each widget's builder function.

#### Binding to the Data Model

To bind a widget's property to the data model, you use a special JSON object in the data sent from the AI. This object can contain either a `literalString` (for static values) or a `path` (to bind to a value in the data model).

For example, to display a user's name in a `Text` widget, the AI would generate:

```json
{
  "Text": {
    "text": {
      "literalString": "Welcome to GenUI"
    },
    "hint": "h1"
  }
}
```

#### Image

```json
{
  "Image": {
    "url": {
      "literalString": "https://example.com/image.png"
    },
    "hint": "mediumFeature"
  }
}
```

#### Updating the Data Model

Input widgets, like `TextField`, update the `DataModel` directly. When the user types in a text field that is bound to `/user/name`, the `DataModel` is updated, and any other widgets bound to that same path will automatically rebuild to show the new value.

This reactive data flow simplifies state management and creates a powerful, high-bandwidth interaction loop between the user, the UI, and the AI.

### Next steps

Check out the [examples](../../examples) included in this repo! The
[travel app](../../examples/travel_app) shows how to define your own widget
`Catalog` that the agent can use to generate domain-specific UI.

If something is unclear or missing, please
[create an issue](https://github.com/flutter/genui/issues/new/choose).

### System instructions

The `genui` package gives the LLM a set of tools it can use to generate
UI. To get the LLM to use these tools, the `systemInstruction` provided to
`ContentGenerator` must explicitly tell it to do so. This is why the previous example
includes a system instruction for the agent with the line "Every time I give
you a word, you should generate UI that displays one new riddle...".

### Troubleshooting / FAQ

#### How can I configure logging?

To observe communication between your app and the agent, enable logging in your
`main` method.

```dart
import 'package:logging/logging.dart';
import 'package:genui/genui.dart';

final logger = configureGenUiLogging(level: Level.ALL);

void main() async {
  logger.onRecord.listen((record) {
    debugPrint('${record.loggerName}: ${record.message}');
  });

  // Additional initialization of bindings and Firebase.
}
```

#### I'm getting errors about my minimum macOS/iOS version.

Firebase has a
[minimum version requirement](https://firebase.google.com/support/release-notes/ios)
for Apple's platforms, which might be higher than Flutter's default. Check your
`Podfile` (for iOS) and `CMakeLists.txt` (for macOS) to ensure you're targeting
a version that meets or exceeds Firebase's requirements.
