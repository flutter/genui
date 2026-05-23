// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genkit/plugin.dart';
import 'package:genkit_chrome/genkit_chrome.dart';

/// Web helper to return the Chrome AI plugin.
List<GenkitPlugin> getPlatformPlugins() => [chromeAI()];
