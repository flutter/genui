#!/bin/bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fast fail the script on failures.
set -ex

cp -f examples/simple_chat/lib/firebase_options_stub.dart examples/simple_chat/lib/firebase_options.dart
cp -f examples/simple_chat/macos/Runner/GoogleService-Info-stub.plist examples/simple_chat/macos/Runner/GoogleService-Info.plist
cp -f examples/simple_chat/ios/Runner/GoogleService-Info-stub.plist examples/simple_chat/ios/Runner/GoogleService-Info.plist
cp -f examples/simple_chat/android/app/google-services-stub.json examples/simple_chat/android/app/google-services.json

cp -f examples/travel_app/lib/firebase_options_stub.dart examples/travel_app/lib/firebase_options.dart
cp -f examples/travel_app/macos/Runner/GoogleService-Info-stub.plist examples/travel_app/macos/Runner/GoogleService-Info.plist
cp -f examples/travel_app/ios/Runner/GoogleService-Info-stub.plist examples/travel_app/ios/Runner/GoogleService-Info.plist
cp -f examples/travel_app/android/app/google-services-stub.json examples/travel_app/android/app/google-services.json
