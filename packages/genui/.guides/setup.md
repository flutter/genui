# Set up of `genui`

Use the following instructions to add `genui` to your Flutter app. The
code examples show how to perform the instructions on a brand new app created by
running `flutter create`.

## 1. Choosing a ContentGenerator

`genui` provides three `ContentGenerator` implementations for connecting to
different types of agent providers. Use the following guide to choose the one
that best fits your needs.

- **`FirebaseAiContentGenerator`**: Use this when you are ready to deploy your
  app. This generator connects to Gemini via Firebase AI Logic, and is the
  recommended approach for production apps.

- **`GoogleGenerativeAiContentGenerator`**: Use this for prototyping and local
  development. This generator connects to the Google Generative AI API using an
  API key, and is a good choice for getting started quickly.

- **`A2uiContentGenerator`**: Use this to connect to a server that implements
  the A2UI protocol. This is a good choice if you have an existing agent that
  you want to connect to `genui`.

## 2. Configure your agent provider

`genui` can connect to a variety of agent providers. Choose the section
below for your preferred provider.

### Configure Firebase AI Logic

To use the built-in `FirebaseContentGenerator` to connect to Gemini via Firebase AI
Logic, follow these instructions:

1. [Create a new Firebase project](https://support.google.com/appsheet/answer/10104995)
   using the Firebase Console. This should be done by a human.
2. [Enable the Gemini API](https://firebase.google.com/docs/gemini-in-firebase/set-up-gemini)
   for that project. This should also be done by a human.
3. Follow the first three steps in
   [Firebase's Flutter Setup guide](https://firebase.google.com/docs/flutter/setup)
   to add Firebase to your app. Run `flutterfire configure` to configure your
   app.
4. In `pubspec.yaml`, add `genui` and `genui_firebase_ai` to the
   `dependencies` section. As of this writing, it's best to use pub's git
   dependency to refer directly to this project's source.

   ```yaml
   dependencies:
     genui: ^0.5.1
     genui_firebase_ai: ^0.5.1
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

### Configure with the A2UI protocol

To use `genui` with a generic agent provider that supports the A2UI protocol,
use the `genui_a2ui` package.

1. In `pubspec.yaml`, add `genui` and `genui_a2ui` to the `dependencies`
   section.

   ```yaml
   dependencies:
     genui: ^0.5.1
     genui_a2ui: ^0.5.1
   ```

2. Use the `A2uiContentGenerator` to connect to your agent provider.

### Configure with Google Generative AI

To use `genui` with the Google Generative AI API, use the
`genui_google_generative_ai` package.

1. In `pubspec.yaml`, add `genui` and `genui_google_generative_ai` to the
   `dependencies` section.

   ```yaml
   dependencies:
     genui: ^0.5.1
     genui_google_generative_ai: ^0.5.1
   ```

2. Use the `GoogleGenerativeAiContentGenerator` to connect to the Google
   Generative AI API. You will need to provide your own API key.

### Connecting to a custom backend

There are two ways to connect to a custom backend.

1.  Use the `genui_a2ui` package to connect to a server that implements the
    A2UI protocol. This is the recommended approach if you have an existing
    agent that you want to connect to `genui`.

2.  Implement your own `ContentGenerator`. This is a good choice if you have a
    custom backend that does not implement the A2UI protocol. This will require
    you to convert your UI data source into a stream of `A2uiMessage` messages
    that can be rendered by the Gen UI SDK.

## 2. Create the connection to an agent

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
