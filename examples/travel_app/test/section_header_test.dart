// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/section_header.dart';

void main() {
  group('sectionHeader', () {
    testWidgets('renders title with a distinct style', (
      WidgetTester tester,
    ) async {
      final data = {
        'title': {'literalString': 'Section Title'},
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return sectionHeader.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {},
                  context: context,
                  dataContext: DataContext(DataModel(), '/'),
                );
              },
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Section Title'));
      expect(title.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('renders title and subtitle with distinct styles', (
      WidgetTester tester,
    ) async {
      final data = {
        'title': {'literalString': 'Section Title'},
        'subtitle': {'literalString': 'Section Subtitle'},
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return sectionHeader.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {},
                  context: context,
                  dataContext: DataContext(DataModel(), '/'),
                );
              },
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Section Title'));
      final subtitle = tester.widget<Text>(find.text('Section Subtitle'));
      expect(title.style?.fontWeight, FontWeight.bold);
      expect(subtitle.style?.color, Colors.grey);
    });
  });
}
