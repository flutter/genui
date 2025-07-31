#!/usr/bin/env bash

set -e

package_path=$1

cd "$package_path"
echo ""
echo "================================================="
echo "Testing package at: $package_path"
echo "================================================="
echo "--- Updating submodules ---"
git submodule update --init --recursive
echo "--- Installing dependencies ---"
dart pub get
echo "--- Checking formatting ---"
dart format --output=none --set-exit-if-changed .
echo "--- Analyzing code ---"
flutter analyze --fatal-infos
if [[ -d "test" ]]; then
  echo "--- Running tests ---"
  flutter test --test-randomize-ordering-seed=random
else
  echo "No test directory in $package_path"
fi
