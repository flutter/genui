# genui_client

A Flutter application demonstrating the use of generative AI to create dynamic, interactive user interfaces.

This project serves as a proof-of-concept for a system where a large language model (LLM) like Google's Gemini can generate a JSON representation of a user interface, which is then rendered natively by a Flutter client. The application also supports a feedback loop where user interactions are sent back to the LLM, enabling it to generate responsive and stateful UI updates.

## How it Works

The core of the application is a continuous interaction loop between the user, the Flutter client, and the AI model:

1. **Prompt**: The user enters a text prompt describing the desired user interface (e.g., "Create a login form with a username field, a password field, and a login button").
2. **Generation**: The prompt is sent to the generative AI model. The model is given instructions to return a JSON object that conforms to a predefined UI schema.
3. **Rendering**: The Flutter client receives the JSON response. A `SurfaceWidget` widget parses the JSON and recursively builds a native Flutter widget tree based on the definition.
4. **Interaction**: The user interacts with the rendered UI (e.g., types in a text field, taps a button).
5. **Event Feedback**: Each interaction generates a `UiEvent` object. This event is sent back to the AI model, framed as a "function call response". This makes the model believe it has invoked a tool that returned the user's action as its result.
6. **Update**: The model processes the event and the conversation history, and can then generate a new JSON UI definition to reflect the new state of the application (e.g., showing a loading spinner after the login button is pressed). This cycle allows for creating truly interactive and stateful applications driven by the AI.

## Supported Widgets

The current UI schema supports the following Flutter widgets:

- `Align`
- `Checkbox`
- `Column`
- `ElevatedButton`
- `Padding`
- `Radio`
- `Row`
- `Slider`
- `Text`
- `TextField`

## Getting Started

To run this application, you will need to have the Flutter SDK installed and a Firebase project configured.

1. **Install dependencies:**

   ```bash
   flutter pub get
   ```

2. **Configure Firebase:** Follow the FlutterFire CLI instructions to configure the project for your target platforms. You will need to place your own `firebase_options.dart` file in the `lib/` directory.
3. **Run the app:**

   ```bash
   flutter run
   ```

## The UI Schema

The contract between the AI model and the Flutter client is defined in `lib/src/ui_schema.dart`. This file contains a `Schema` object that details the expected structure of the JSON UI definition, including the available widget types and their supported properties. This schema is crucial for ensuring the model generates valid and renderable UI.
