# GenUI Usage

This guidance explains how to enable GenUI for your
[Flutter project](https://docs.flutter.dev/reference/create-new-app).

## Getting Started

### Configure Firebase

1. [Create a new Firebase project](https://support.google.com/appsheet/answer/10104995) with Firebase Console.

1. [Enable Gemini](https://firebase.google.com/docs/gemini-in-firebase/set-up-gemini)
for the project.

1. Follow [the steps](https://firebase.google.com/docs/flutter/setup)
to configure Firebase for your Flutter project.

    NOTE: see how secure it is to publish the generated files
    [here](https://firebase.google.com/docs/projects/learn-more#config-files-objects).

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

