#!/usr/bin/env bash
# Copyright 2025 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

git clone -b stable https://github.com/flutter/flutter.git $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter precache
