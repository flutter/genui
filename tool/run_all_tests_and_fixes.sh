#!/bin/bash
# Copyright 2025 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Move to the repository root to ensure paths are correct.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd -- "$SCRIPT_DIR/.."

set -e
set -o pipefail

command -v dart >/dev/null 2>&1 || { echo >&2 "Error: 'dart' command not found. Please ensure the Dart SDK is installed and in your PATH."; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo >&2 "Error: 'flutter' command not found. Please ensure the Flutter SDK is installed and in your PATH."; exit 1; }

# This script runs all automated fixes and tests for the repo, reporting all
# errors that cannot be fixed automatically.
#
# This allows for more efficient use of LLM-based tools to fix errors by running
# all the diagnostic tools up-front instead of relying on separate LLM tool
# calls for each one.

FAILURE_LOG=$(mktemp)
trap 'rm -f "$FAILURE_LOG"' EXIT

readonly PROJECT_TOTAL_STEPS=3

run_project_step() {
    local project_dir="$1"
    local description="$2"
    local step_num="$3"
    shift 3
    local cmd_str=$(printf '%q ' "$@"); cmd_str=${cmd_str% }

    echo "[$step_num/$PROJECT_TOTAL_STEPS] $description..."
    echo "To rerun this command:"
    echo "cd \"$project_dir\" && $cmd_str"
    if ! "$@"; then
        echo "'$cmd_str' failed in \"$project_dir\"" >> "$FAILURE_LOG"
    fi
}


# --- 0. Run commands at the root project level ---
echo "Running root-level commands..."
echo "--------------------------------------------------"
# Check if the copyright tool exists before running
if [ -f "tool/fix_copyright/bin/fix_copyright.dart" ]; then
    echo "Running copyright fix. To rerun:"
    echo "dart run tool/fix_copyright/bin/fix_copyright.dart --force"
    # Log failures without stopping the script.
    dart run tool/fix_copyright/bin/fix_copyright.dart --force || echo "'dart run tool/fix_copyright/bin/fix_copyright.dart --force' failed" >> "$FAILURE_LOG"
else
    echo "Warning: Copyright tool not found. Skipping."
fi
# Log failures without stopping the script.
echo "Running dart format. To rerun:"
echo "dart format ."
dart format . || echo "'dart format .' failed" >> "$FAILURE_LOG"
echo "Root-level commands complete."
echo ""

# --- 1. Find all Flutter projects ---
# We find all `pubspec.yaml` files and process each one.
# The `find ... -print0 | while ...` construct safely handles file paths with spaces.
echo "Searching for Flutter projects..."
echo "=================================================="
find . -name "build" -type d -prune -o -name ".dart_tool" -type d -prune -o -path "./melos_tool" -prune -o -name "pubspec.yaml" -exec grep -q 'sdk: flutter' {} \; -print0 | while IFS= read -r -d '' pubspec_path; do
    (
        # Get the directory containing the pubspec.yaml file.
        project_dir=$(dirname "$pubspec_path")

        echo "Processing project in: $project_dir"
        echo "--------------------------------------------------"

        # Navigate into the project's directory.
        cd "$project_dir" || exit 1

        run_project_step "$project_dir" "Applying fixes with 'dart fix --apply'" 1 dart fix --apply
        echo ""
        run_project_step "$project_dir" "Running tests with 'flutter test'" 2 flutter test
        echo ""
        run_project_step "$project_dir" "Analyzing code with 'flutter analyze'" 3 flutter analyze

        echo "Finished processing $project_dir."
        echo ""
    )
done

echo "=================================================="
echo "      All projects have been processed."
echo "=================================================="

if [ -s "$FAILURE_LOG" ]; then
  echo "Tooling errors occurred:" >&2
  cat "$FAILURE_LOG" >&2
  exit 1
fi
