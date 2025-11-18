#!/bin/bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Run this script if you're not planning on running the examples, but you
# just don't want to see analyzer issues.  See refresh_firebase.sh for
# instructions on how to run the examples.

# Fast fail the script on failures.
set -ex

cp -f examples/travel_app/lib/firebase_options_stub.dart examples/travel_app/lib/firebase_options.dart
cp -f examples/simple_chat/lib/firebase_options_stub.dart examples/simple_chat/lib/firebase_options.dart
