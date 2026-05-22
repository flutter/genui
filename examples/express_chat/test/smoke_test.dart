// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:express_chat/agent/api_key/_io_api_key.dart';
import 'package:express_chat/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    debugApiKey = 'dummy_api_key';
  });

  tearDown(() {
    debugApiKey = null;
  });

  testWidgets('Smoke test: App starts without issues', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(ChatScreen), findsOneWidget);
  });
}
