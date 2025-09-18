#!/bin/bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `pub get` for all code in the repo.

# Fast fail the script on failures.
set -ex

cp -f examples/travel_app/lib/firebase_options_stub.dart examples/travel_app/lib/firebase_options.dart
cp -f examples/simple_chat/lib/firebase_options_stub.dart examples/simple_chat/lib/firebase_options.dart
