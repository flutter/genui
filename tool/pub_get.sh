#!/bin/bash

# Copyright 2023 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs `pub get` for all code in the repo.

# Fast fail the script on failures.
set -ex

# The directory that this script is located in.
TOOL_DIR=`dirname "$0"`

cd $TOOL_DIR/../examples/generic_chat
flutter pub get
cd -

cd $TOOL_DIR/../examples/travel_app
flutter pub get
cd -

cd $TOOL_DIR/../examples/travel_app_hardcoded
flutter pub get
cd -

cd $TOOL_DIR/../pkgs/dart_schema_builder
dart pub get
cd -

cd $TOOL_DIR/../pkgs/flutter_genui
flutter pub get
cd -

cd $TOOL_DIR/../pkgs/spikes/fcp_client
flutter pub get
cd -
