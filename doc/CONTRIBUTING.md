# Contributing to Flutter GenUI

Please follow our [contributor guidelines](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md).

## Firebase Configuration

The app uses `firebase_ai` to connect to the LLM, which requires using Firebase.

To configure firebase, run `flutterfire`.

First, activate `flutterfire`:

```shell
dart pub global activate flutterfire_cli
```

The configure it:

```shell
flutterfire configure --overwrite-firebase-options --platforms=web,macos,android --project=fluttergenui
```

You can configure the project on the Google Cloud Console for the [FlutterGenUI project](https://pantheon.corp.google.com/welcome?inv=1&invt=Ab4FMw&project=fluttergenui).
