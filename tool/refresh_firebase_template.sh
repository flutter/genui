#!/bin/bash
# Copyright 2025 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `flutterfire configure` for the examples, to refresh firebase configuration.
#
# Prerequisites:
#   1. follow https://github.com/flutter/genui/blob/main/doc/USAGE.md#configure-firebase
#.  2. Run 'firebase login' to authenticate with Firebase CLI.
#
# To run this script for your firebase project:
#   1. Copy the script to `refresh_firebase.sh` (it will be gitignored).
#   2. Edit the script to set the `--project` flag to your firebase project ID.
#   3. Run the script with one of two ways:
#      - Run `sh tool/refresh_firebase.sh`
#      - Open in VSCode and  press `Cmd+Shift+B`.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$(dirname "$0")

cd "$TOOL_DIR/../examples/minimal_genui"
rm -rf lib/firebase_options.dart
flutterfire configure \
   --overwrite-firebase-options \
   --platforms=macos \
   --project=fluttergenui \
   --out=lib/firebase_options.dart
cd -

cd "$TOOL_DIR/../examples/travel_app"
rm -rf lib/firebase_options.dart
flutterfire configure \
   --overwrite-firebase-options \
   --platforms=macos \
   --project=fluttergenui \
   --out=lib/firebase_options.dart
cd -
