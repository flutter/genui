// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genkit/genkit.dart';
import 'package:genkit_chrome/genkit_chrome.dart';

/// Web implementation of Chrome AI plugin registration.
void registerChromeAI(Genkit ai) {
  ai.use(chromeAI());
}
