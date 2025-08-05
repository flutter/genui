// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/trailhead.dart';

void main() {
  group('trailheadCatalogItem', () {
    testWidgets('builds widget correctly', (WidgetTester tester) async {
      final data = {
        'topics': ['Topic A', 'Topic B'],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return trailheadCatalogItem.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Topic A'), findsOneWidget);
      expect(find.text('Topic B'), findsOneWidget);
    });
  });
}
