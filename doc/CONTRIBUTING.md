# Contributing to Flutter GenUI

## Guidelines

Please follow
[Flutter contributor guidelines](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md).

## Firebase Configuration

NOTE: For Google-internal projects see go/flutter-genui-internal.

To run examples:

1. [Create a new project](https://support.google.com/appsheet/answer/10104995) with Firebase Console.

The app uses `firebase_ai` to connect to the LLM, which requires using Firebase.

To configure firebase, follow
[Firebase guidance](https://firebase.google.com/docs/flutter/setup)
for your Google account and instead of just `flutterfire configure` run:

```shell
flutterfire configure \
    --overwrite-firebase-options \
    --platforms=web,macos,android \
    --project=<your Firebase project name> \
    --out=lib/firebase_options.dart
```

Guidances:
* https://firebase.google.com/docs/ai-logic/get-started?platform=flutter&api=vertex#prereqs
* https://firebase.google.com/docs/flutter/setup

## Shell scripts

To run a script in `tool/`, open the script in VSCode and press ⇧⌘B.
