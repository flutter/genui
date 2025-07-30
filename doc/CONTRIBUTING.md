# Contributing to Flutter GenUI

Please follow our
[contributor guidelines](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md).

## Firebase Configuration

The app uses `firebase_ai` to connect to the LLM, which requires using Firebase.

To configure firebase for a new Google internal project, follow
[Firebase guidance](https://firebase.google.com/docs/flutter/setup)
for your Google account and instead of just `flutterfire configure` run:

```shell
flutterfire configure \
    --overwrite-firebase-options \
    --platforms=web,macos,android \
    --project=fluttergenui \
    --out=lib/firebase_options.dart
```

Guidances:
* https://firebase.google.com/docs/ai-logic/get-started?platform=flutter&api=vertex#prereqs
* https://firebase.google.com/docs/flutter/setup

See the project's `fluttergenui` details
[here](https://pantheon.corp.google.com/welcome?inv=1&invt=Ab4FMw&project=fluttergenui).
