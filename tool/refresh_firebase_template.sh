#!/bin/bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Template script to run `flutterfire configure` for the examples,
# to refresh firebase configuration.
#
# Prerequisites:
#   1. Follow https://github.com/flutter/genui/blob/main/doc/USAGE.md#configure-firebase
#   2. Run 'firebase login' to authenticate with Firebase CLI.
#
# To run this script for your firebase project:
#   1. Copy the script to `refresh_firebase.sh` (it will be gitignored).
#   2. Update value of PROJECT_ID to to be your firebase project ID.
#   3. Run the script with one of two ways:
#      - Run `sh tool/refresh_firebase.sh`
#      - Open in VSCode and  press `Cmd+Shift+B`.
# Troubleshooting:
#   1. If the script fails with "No Firebase project found",
#      run `firebase logout` and `firebase login`.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$(dirname "$0")

PROJECT_ID="fluttergenui"

EXAMPLES=(
    "simple_chat"
    "travel_app"
)

for example in "${EXAMPLES[@]}"; do
    echo "--- Configuring Firebase for $example ---"
    (
        cd "$TOOL_DIR/../examples/$example"
        rm -f lib/firebase_options.dart
        flutterfire configure \
           --overwrite-firebase-options \
           --platforms=macos,web,ios,android \
           --project="$PROJECT_ID" \
           --out=lib/firebase_options.dart
    )
done
