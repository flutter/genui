# GenUI Usage

This guidance explains how to enable GenUI for your
[Flutter project](https://docs.flutter.dev/reference/create-new-app).

## Getting Started

### Configure Firebase

1. [Create a new Firebase project](https://support.google.com/appsheet/answer/10104995) with Firebase Console.

1. [Enable Gemini](https://firebase.google.com/docs/gemini-in-firebase/set-up-gemini)
for the project.

  TODO: check if GenUI will work without this step.

1. Follow [the steps](https://firebase.google.com/docs/flutter/setup)
to configure your Flutter project.

    NOTE: see how secure it is to publish the generated files
    [here](https://firebase.google.com/docs/projects/learn-more#config-files-objects).

1. If you run your Flutter project on ios or macos platform, add this key to your
`<platform>/Runner/*.entitlements`:

  ```xml
  <dict>
    ...
    <key>com.apple.security.network.client</key>
    <true/>
  </dict>
  ```

### Employ `flutter_genui`

1. Add dependency to `flutter_genui` with one of options:

  * `flutter pub add flutter_genui`

  * Reference by path in pubspec.yaml:

    ```
    flutter_genui:
        path: <path to flutter_genui>
    ```

2. Invoke before `runApp`:

  ```dart
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ```

