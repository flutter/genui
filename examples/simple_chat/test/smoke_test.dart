// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_chat/api_key/io_get_api_key.dart';
import 'package:simple_chat/main.dart';

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
