#!/usr/bin/env bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fixes copyright headers to make bots happy.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$(dirname $(realpath "${BASH_SOURCE[0]}"))

# The year is hardcoded to 2025, year of project creation.
dart "$TOOL_DIR/fix_copyright/bin/fix_copyright.dart" --year 2025 --force "$@"
