#!/usr/bin/env bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `pub get` for all code in the repo.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$(dirname $(realpath "${BASH_SOURCE[0]}"))

# Change to the root of the repository to make paths simpler.
cd "$TOOL_DIR/.."

find . -name "pubspec.yaml" -exec dirname {} \; | xargs -I {} sh -c 'echo "Running pub upgrade in {}"; (cd "{}" && flutter pub upgrade)'
