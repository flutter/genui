#!/bin/bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Template script to run `flutterfire configure` for the examples,
# to refresh firebase configuration.
#
# Prerequisites:
#   1. Follow https://github.com/flutter/genui/blob/main/packages/genui/README.md#configure-firebase-ai-logic
#   2. Run 'firebase login' to authenticate with Firebase CLI.
#
# You can run the script with the ID of your project as the first argument,
# or you can run it without any arguments, in which case it will use the
# default project ID in the environment variable GENUI_PROJECT_ID, or
# `fluttergenui` if that is not set.
#
# Run `sh tool/refresh_firebase.sh` to run the script.
#
# Troubleshooting:
#   1. If the script fails with "No Firebase project found",
#      run `firebase logout` and `firebase login`.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$(dirname "$0")

DEFAULT_PROJECT_ID=${GENUI_PROJECT_ID:-"fluttergenui"}

PROJECT_ID=${1:-${DEFAULT_PROJECT_ID}}

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
