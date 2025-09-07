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
LOG_DIR=$(mktemp -d)
trap 'rm -f "$FAILURE_LOG"; rm -rf "$LOG_DIR"' EXIT

readonly PROJECT_TOTAL_STEPS=4

run_project_step() {
    local project_dir="$1"
    local description="$2"
    local step_num="$3"
    shift 3
    local cmd_to_run=($@)
    local cmd_str_to_run=$(printf '%q ' "${cmd_to_run[@]}"); cmd_str_to_run=${cmd_str_to_run% }

    # Create a version of the command for display, removing the reporter flag.
    local cmd_for_display=()
    for arg in "${cmd_to_run[@]}"; do
        if [[ "$arg" != "--reporter=failures-only" ]]; then
            cmd_for_display+=("$arg")
        fi
    done
    local cmd_str_for_display=$(printf '%q ' "${cmd_for_display[@]}"); cmd_str_for_display=${cmd_str_for_display% }

    echo ""
    echo "### [$step_num/$PROJECT_TOTAL_STEPS] $description"
    echo "> To rerun this command:"
    echo "> 
> (cd \"$project_dir\" && $cmd_str_for_display)
> "
    if ! "${cmd_to_run[@]}"; then
        echo "'(cd \"$project_dir\" && $cmd_str_to_run)' failed" >> "$FAILURE_LOG"
    fi
}

process_project() {
    local project_dir="$1"
    (
        echo "## Processing project in: \`$project_dir\`"
        echo "---"

        # Navigate into the project's directory.
        cd "$project_dir" || exit 1

        run_project_step "$project_dir" "Applying fixes with 'dart fix --apply'" 1 dart fix --apply
        run_project_step "$project_dir" "Formatting with 'dart format .'" 2 dart format .
        if [ -d "test" ]; then
            run_project_step "$project_dir" "Running tests with 'flutter test'" 3 flutter test --reporter=failures-only
        else
            echo ""
            echo "### [3/$PROJECT_TOTAL_STEPS] Skipping tests, no 'test' directory found."
        fi
        run_project_step "$project_dir" "Analyzing code with 'flutter analyze'" 4 flutter analyze

        echo ""
        echo "---"
        echo "Finished processing \`$project_dir\`."
        echo ""
    )
}

# --- 0. Run commands at the root project level ---
echo "## Running root-level commands"
echo "---"
# Check if the copyright tool exists before running
if [ -f "tool/fix_copyright/bin/fix_copyright.dart" ]; then
    echo "### Running copyright fix"
    echo "> To rerun this command:"
    echo "> 
> dart run tool/fix_copyright/bin/fix_copyright.dart --force
> "
    # Log failures without stopping the script.
    dart run tool/fix_copyright/bin/fix_copyright.dart --force >/dev/null 2>&1 || true
else

    echo "### Skipping copyright fix: tool not found."
fi
echo "---"
echo "Root-level commands complete."
echo ""

# --- 1. Find all Flutter projects ---
# We find all `pubspec.yaml` files and process each one.
# The `find ... -print0 | while ...` construct safely handles file paths with spaces.
echo "Searching for Flutter projects..."

# Collect all project directories first to process them in a stable order.
project_dirs=()
while IFS= read -r -d '' pubspec_path; do
    project_dirs+=("$(dirname "$pubspec_path")")
done < <(find . -name "build" -type d -prune -o -name ".dart_tool" -type d -prune -o -path "./melos_tool" -prune -o -path "./packages/spikes" -prune -o -name "pubspec.yaml" -exec grep -q 'sdk: flutter' {} \; -print0)

# Run processing in parallel for each project.
pids=()
log_files=()
for i in "${!project_dirs[@]}"; do
    project_dir="${project_dirs[$i]}"
    log_file="$LOG_DIR/project_$i.log"
    log_files+=("$log_file")

    # Run the processing in the background, redirecting output to the log file.
    process_project "$project_dir" > "$log_file" 2>&1 &
    pids+=($!)
done

# Wait for all background jobs to complete.
echo "## Running tests and analysis for ${#project_dirs[@]} projects in parallel"
for project_dir in "${project_dirs[@]}"; do
    echo "- \`$project_dir\`"
done
echo ""
wait "${pids[@]}"
echo "## All projects have been processed."
echo "=================================================="
echo ""

# Print the logs from each project in the original order.
for log_file in "${log_files[@]}"; do
    cat "$log_file"
done

if [ -s "$FAILURE_LOG" ]; then
  echo ""
  echo "## Tooling errors occurred:" >&2
  echo '
```' >&2
  cat "$FAILURE_LOG" >&2
  echo '
```' >&2
  exit 1
fi