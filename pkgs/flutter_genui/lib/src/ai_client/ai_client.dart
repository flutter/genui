// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'tools.dart';

/// An abstract class for an AI model.
abstract class AiModel {
  /// The display name of the model.
  String get displayName;
}

abstract interface class AiClient {
  ValueListenable<AiModel> get model;
  List<AiModel> get models;
  void switchModel(AiModel model);

  Future<T?> generateContent<T extends Object>(
    List<Content> conversation,
    Schema outputSchema, {
    Iterable<AiTool> additionalTools = const [],
  });
}
