// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:composer/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ComposerApp());
    expect(find.text('Gallery'), findsOneWidget);
  });
}
