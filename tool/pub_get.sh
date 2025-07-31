#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `pub get` for all code in the repo.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$(dirname "$0")

# Change to the root of the repository to make paths simpler.
cd "$TOOL_DIR/.."

FLUTTER_PACKAGES=(
    "examples/generic_chat"
    "examples/travel_app"
    "examples/travel_app_hardcoded"
    "pkgs/flutter_genui"
    "pkgs/spikes/fcp_client"
)

DART_PACKAGES=(
    "pkgs/dart_schema_builder"
)

for pkg in "${FLUTTER_PACKAGES[@]}"; do
    echo "--- Running flutter pub get in $pkg ---"
    (cd "$pkg" && flutter pub get)
done

for pkg in "${DART_PACKAGES[@]}"; do
    echo "--- Running dart pub get in $pkg ---"
    (cd "$pkg" && dart pub get)
done
