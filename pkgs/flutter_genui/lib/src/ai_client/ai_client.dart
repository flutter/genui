// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart';

import 'tools.dart';

abstract interface class AiClient {
  Future<T?> generateContent<T extends Object>(
    List<Content> conversation,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
  });
}
