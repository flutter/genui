# Set up of `flutter_genui`

Use the following instructions to add `flutter_genui` to your Flutter app. The
code examples show how to perform the instructions on a brand new app created by
running `flutter create`.

## 1. Configure your agent provider

`flutter_genui` can connect to a variety of agent providers. Choose the section
below for your preferred provider.

### Configure Firebase AI Logic

To use the built-in `FirebaseAiClient` to connect to Gemini via Firebase AI
Logic, follow these instructions:

1. [Create a new Firebase project](https://support.google.com/appsheet/answer/10104995)
   using the Firebase Console. This should be done by a human.
2. [Enable the Gemini API](https://firebase.google.com/docs/gemini-in-firebase/set-up-gemini)
   for that project. This should also be done by a human.
3. Follow the first three steps in
   [Firebase's Flutter Setup guide](https://firebase.google.com/docs/flutter/setup)
   to add Firebase to your app. **Ask me to run `flutterfire configure` for you.**
4. In `pubspec.yaml`, add `flutter_genui` and `flutter_genui_firebase_ai` to the
   `dependencies` section. As of this writing, it's best to use pub's git
   dependency to refer directly to this project's source.

    ```yaml
    dependencies:
      # ...
      flutter_genui:
        git:
          url: https://github.com/flutter/genui.git
          path: packages/flutter_genui
          ref: fc7efa9c69529b655e531f3037bb12b9b241d6aa
      flutter_genui_firebase_ai:
        git:
          url: https://github.com/flutter/genui.git
          path: packages/flutter_genui_firebase_ai
          ref: fc7efa9c69529b655e531f3037bb12b9b241d6aa
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

### Configure another agent provider

To use `flutter_genui` with another agent provider, you need to follow that
provider's instructions to configure your app, and then create your own subclass
of `AiClient` to connect to that provider. Use `FirebaseAiClient` as an example
of how to do so.

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