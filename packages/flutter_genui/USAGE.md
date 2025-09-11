# GenUI Usage

This guidance explains how to enable GenUI for your [Flutter project](https://docs.flutter.dev/reference/create-new-app).

## Hello World

This section describes how to build a minimal GenUI interaction.

### Configure Firebase

1. [Create a new Firebase project](https://support.google.com/appsheet/answer/10104995) with Firebase Console.

1. [Enable Gemini](https://firebase.google.com/docs/gemini-in-firebase/set-up-gemini)
   for the project.

1. Follow [the steps](https://firebase.google.com/docs/flutter/setup)
   to configure your Flutter project.

If `flutterfire configure` fails, try one or all of these:

- delete existing `lib/firebase_options.dart`
- switch to flutter stable
- run `flutter clean` and `flutter upgrade` for the project
- recreate firebase project
- remove a platform folder in flutter project and re-add it with flutter stable by running the create command `flutter create --platforms=web,macos .`

> Security: It is secure to publish the generated Firebase configuration files, even though they contain the string "apiKey" with a key. See [the Firebase documentation](https://firebase.google.com/docs/projects/learn-more#config-files-objects) for more information.

1. If you run your Flutter project on the `ios` or `macos` platform, add this key to your
   `{ios,macos}/Runner/*.entitlements` file(s):

   ```xml
   <dict>
   ...
   <key>com.apple.security.network.client</key>
   <true/>
   </dict>
   ```

1. Every time you clone your repo, re-run `flutterfire configure`, or take advantage of
`tool/refresh_firebase_template.sh`.

### Employ `flutter_genui`

For a complete example, refer to [main.dart in the simple_chat example](../../examples/simple_chat/lib/main.dart). The following steps outline the details of setting up your project to use `flutter_genui`:

1. In your `pubspec.yaml` file, add `flutter_genui` and `flutter_genui_firebase_ai` to the `dependencies` section with one of the following options:

   - Reference the github project directly:

   ```yaml
   flutter_genui:
     git:
       url: https://github.com/flutter/genui.git
       path: packages/flutter_genui
   flutter_genui_firebase_ai:
     git:
       url: https://github.com/flutter/genui.git
       path: packages/flutter_genui_firebase_ai
   ```

   - In the future: download from [pub.dev](https://pub.dev)! (We're not ready to publish this as a package until the API is more stable.)

2. Invoke `Firebase.initializeApp` before `runApp`:

   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```

3. In a `StatefulWidget`, create and initialize a `UiAgent`. The `UiAgent` is the main entry point for the GenUI package. It requires a system instruction prompt.

   ```dart
   late final UiAgent uiAgent;

   @override
   void initState() {
     super.initState();
     final genUiManager = GenUiManager(catalog: CoreCatalogItems.asCatalog());
     final aiClient = FirebaseAiClient(
       systemInstruction: 'You are a helpful AI assistant.',
       tools: genUiManager.getTools(),
     );
     uiAgent = UiAgent(
       genUiManager: genUiManager,
       aiClient: aiClient,
       onSurfaceAdded: _onSurfaceAdded,
     );
   }
   ```

4. The `UiAgent` needs callbacks to handle UI updates from the AI. In this minimal example, we handle `onSurfaceAdded` to display the generated UI.

   ```dart
   final List<GenUiUpdate> _updates = [];

   void _onSurfaceAdded(SurfaceAdded update) {
     setState(() {
       _updates.add(update);
     });
   }
   ```

5. In your widget's `build` method, render the UI surfaces that the AI creates. You can use a `ListView` to display multiple surfaces. Each surface is rendered using the `GenUiSurface` widget.

   ```dart
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(title: const Text('Minimal GenUI App')),
       body: Column(
         children: [
           Expanded(
             child: ListView.builder(
               itemCount: _updates.length,
               itemBuilder: (context, index) {
                 final update = _updates[index];
                 return GenUiSurface(
                   host: uiAgent.host,
                   surfaceId: update.surfaceId,
                   onEvent: (event) {
                     // Handle UI events from the generated surface
                   },
                 );
               },
             ),
           ),
           // Add a chat input widget here
         ],
       ),
     );
   }
   ```

6. Create a method to send user input to the `UiAgent`. This will trigger the AI to generate a response.

   ```dart
   void _sendPrompt(String text) {
     if (text.trim().isEmpty) return;
     uiAgent.sendRequest(UserMessage.text(text));
   }
   ```

7. Connect this method to a text input field to complete the interaction loop.

## Enhance to GenUI Application

Get inspired by our examples. Most will require you to [configure Firebase](#configure-firebase) first.

Then apply what you learned to your app!

If something is unclear or missing, please [create an issue](https://github.com/flutter/genui/issues/new/choose).

## Troubleshooting

### Configure logging

To observe interaction between app and agent, enable logging:

```dart
final logger = configureGenUiLogging(level: Level.ALL);
logger.onRecord.listen((record) {
  print(
    '${record.loggerName}: ${record.message}',
  );
});
```

### Higher minimum macOS version is required

If you are getting the error similar to one below, re-clone your repo.

```
The pod "Firebase/CoreOnly" required by the plugin "firebase_app_check" requires a higher minimum macOS deployment version than the plugin's reported minimum version.
To build, remove the plugin "firebase_app_check", or contact the plugin's developers for assistance.
Error: Error running pod install
```
