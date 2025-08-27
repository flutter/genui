# Minimal GenUI Example

This application is a minimal demonstration of the `flutter_genui` package. It
showcases the simplest way to create a dynamic, conversational user interface
powered by a generative AI model (like Google's Gemini) with just a few lines
of code.

Unlike the more comprehensive [Travel App](../travel_app/README.md) example,
this app does not use a custom widget catalog. Instead, it relies on the default
set of widgets provided by `flutter_genui`, making it an excellent starting
point for understanding the core concepts of the package.

## How it Works

The application initializes and runs the `GenUiManager` in its chat
configuration. The conversation flow is straightforward:

1. **User Prompt**: The user types a request into the chat input field.
2. **AI-Generated UI**: The AI receives the prompt and, guided by a simple
   system instruction in `lib/main.dart`, generates a response using the
   default catalog of widgets (e.g., `text`, `row`, `column`,
   `elevatedButton`).
3. **User Interaction**: The user can interact with any generated UI elements
   (like buttons), and these interactions are sent back to the AI as events to
   continue the conversation.

## Key Features Demonstrated

- **Minimal Setup**: Shows the essential code needed to get a `GenUiManager` up
  and running.
- **Default Widget Catalog**: Demonstrates the power of the pre-built widget
  catalog that comes with `flutter_genui`, allowing the AI to create useful UIs
  without any custom widget definitions.
- **System Prompt Engineering**: A basic system prompt in `lib/main.dart` guides
  the AI's behavior.
- **Firebase Integration**: The application is configured to use Firebase for
  backend services, as shown in `lib/firebase_options.dart`.

## Getting Started

To run this application, you will need to have a Firebase project set up and
configured.

1. **Configure Firebase**: Follow the instructions to add Firebase to your
   Flutter app for the platforms you intend to support (Android, iOS, web,
   etc.). See [flutter_genui's USAGE.md](../../packages/flutter_genui/USAGE.md) for steps to
   configure Firebase. You will need to replace the placeholder values in
   `lib/firebase_options.dart` with the configuration from your own Firebase
   project.
2. **Run the App**: Once Firebase is configured, you can run the app like any
   other Flutter project:

   ```bash
   flutter run
   ```
