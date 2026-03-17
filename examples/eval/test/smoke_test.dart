// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:simple_chat/simple_chat.dart' as sc;

import 'test_infra/ai_client.dart';

void main() {
  test(
    'Model respects configuration of prompt builder in simple chat example.',
    () async {
      final session = sc.ChatSession(aiClient: sc.DartanticAiClient());
    },
  );
}
