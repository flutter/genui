#!/bin/bash
# Copyright 2025 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# This script automates maintenance tasks for Flutter projects.
# It runs root-level commands, then finds all nested Flutter projects
# (identified by a pubspec.yaml file) to run fixes, tests, and analysis.

# Exit immediately if a command exits with a non-zero status to prevent errors.
# We will allow specific commands to fail by using '|| true'.
set -e

# --- 0. Run commands at the root project level ---
echo "Running root-level commands..."
echo "--------------------------------------------------"
# Check if the copyright tool exists before running
if [ -f "tool/fix_copyright/bin/fix_copyright.dart" ]; then
    # Allow this command to fail without stopping the script.
    dart run tool/fix_copyright/bin/fix_copyright.dart --force || true
else
    echo "Warning: Copyright tool not found. Skipping."
fi
# Allow this command to fail without stopping the script.
dart format . || true
echo "Root-level commands complete."
echo ""

# Save the current working directory to return to it after processing sub-projects.
ROOT_DIR=$(pwd)

# --- 1. Find all Flutter projects ---
# We find all `pubspec.yaml` files and process each one.
# The `find ... -print0 | while ...` construct safely handles file paths with spaces.
echo "Searching for Flutter projects..."
echo "=================================================="
find . -name "pubspec.yaml" -print0 | while IFS= read -r -d '' pubspec_path; do
    # Get the directory containing the pubspec.yaml file.
    project_dir=$(dirname "$pubspec_path")

    echo "Processing project in: $project_dir"
    echo "--------------------------------------------------"

    # Navigate into the project's directory.
    cd "$project_dir"

    # --- 2. For each project, run dart fix ---
    echo "[1/3] Applying fixes with 'dart fix --apply'..."
    # Allow this command to fail without stopping the script.
    dart fix --apply || true

    # --- 3. For each project, run tests and analysis, letting them output naturally ---
    echo "[2/3] Running tests with 'flutter test'..."
    echo "--- flutter test: $project_dir ---"
    # The '|| true' ensures that the script continues even if tests fail.
    flutter test || true

    echo "[3/3] Analyzing code with 'flutter analyze'..."
    echo "--- flutter analyze: $project_dir ---"
    # The '|| true' ensures that the script continues even if analysis finds issues.
    flutter analyze || true

    # Return to the original root directory before processing the next project.
    cd "$ROOT_DIR"
    echo "Finished processing $project_dir."
    echo ""
done

echo "=================================================="
echo "      All projects have been processed."
echo "=================================================="

