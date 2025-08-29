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

### Employ `flutter_genui`

For a complete example, refer to [main.dart in the minimal_genui example](../../examples/minimal_genui/lib/main.dart). The following steps outline the details of setting up your project to use `flutter_genui`:

1. In your `pubspec.yaml` file, add `flutter_genui` to the `dependencies` section with one of the following options:

   - Reference the github project directly:

   ```yaml
   flutter_genui:
   git:
     url: https://github.com/flutter/genui.git
     path: packages/flutter_genui
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
     uiAgent = UiAgent(
       'You are a helpful AI assistant.',
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

Get inspired by our examples. The [`minimal_genui`](../../examples/minimal_genui/) example is a great starting point. You can find other examples under development in the [`examples/`](../../examples/) directory. Most will require you to [configure Firebase](#configure-firebase) first.

Then apply what you learned to your app!

If something is unclear or missing, please [create an issue](https://github.com/flutter/genui/issues/new/choose).
