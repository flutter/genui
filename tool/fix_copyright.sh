#!/bin/bash
# Copyright 2025 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fixes copyright headers to make bots happy.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=$(dirname "$0")

(
  cd "$TOOL_DIR/.."
  dart tool/fix_copyright/bin/fix_copyright.dart --year 2025 --force
)
