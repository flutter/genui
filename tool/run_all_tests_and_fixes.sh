#!/bin/bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Move to the repository root to ensure paths are correct.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd -- "$SCRIPT_DIR/.."

set -e
set -o pipefail

command -v dart >/dev/null 2>&1 || { echo >&2 "Error: 'dart' command not found. Please ensure the Dart SDK is installed and in your PATH."; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo >&2 "Error: 'flutter' command not found. Please ensure the Flutter SDK is installed and in your PATH."; exit 1; }

dart run "$SCRIPT_DIR/test_and_fix/bin/test_and_fix.dart" "$@"