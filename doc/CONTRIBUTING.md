# Contributing to Flutter GenUI

Please follow our [contributor guidelines](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md).

## Firebase Configuration

The app uses `firebase_ai` to connect to the LLM, which requires using Firebase.

To configure firebase for a new Dash project, run `flutterfire`:

1. Activate `flutterfire`:

    ```shell
    dart pub global activate flutterfire_cli
    ```

2. `firebase login` with Google credentials

3. Configure firebase in the project directory:

    ```shell
    flutterfire configure --overwrite-firebase-options --platforms=web,macos,android --project=fluttergenui
    ```
TODO: figure out how to generate lib/firebase_options.dart, .firebaserc and firebase.json

Guidances:
https://firebase.google.com/docs/ai-logic/get-started?platform=flutter&api=vertex#prereqs
https://firebase.flutter.dev/docs/overview

See `fluttergenui` details [here](https://pantheon.corp.google.com/welcome?inv=1&invt=Ab4FMw&project=fluttergenui).
