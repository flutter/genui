// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/tabbed_sections.dart';

void main() {
  group('TabbedSections', () {
    testWidgets('renders tabs and content correctly', (
      WidgetTester tester,
    ) async {
      // Mock buildChild function
      Widget mockBuildChild(String id) {
        if (id == 'child1') {
          return const Text('Content for Tab 1');
        } else if (id == 'child2') {
          return const Text('Content for Tab 2');
        }
        return const Text('Unknown Content');
      }

      // Create a CatalogItem instance with test data
      final catalogItem = tabbedSections;
      final data = {
        'sections': [
          {'title': 'Tab 1', 'child': 'child1'},
          {'title': 'Tab 2', 'child': 'child2'},
        ],
      };

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      return catalogItem.widgetBuilder(
                        data: data,
                        id: 'test_tabbed_sections',
                        buildChild: mockBuildChild,
                        dispatchEvent: (event) {},
                        context: context,
                        values: {},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify that the tab titles are displayed
      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);

      // Verify that the content of the first tab is displayed
      expect(find.text('Content for Tab 1'), findsOneWidget);
      expect(
        find.text('Content for Tab 2'),
        findsNothing,
      ); // Second tab content should not be visible initially

      // Tap on the second tab
      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      // Verify that the content of the second tab is now displayed
      expect(find.text('Content for Tab 1'), findsNothing);
      expect(find.text('Content for Tab 2'), findsOneWidget);
    });

    testWidgets('renders with fixed height when height is provided', (
      WidgetTester tester,
    ) async {
      // Mock buildChild function
      Widget mockBuildChild(String id) {
        return const Text('Content');
      }

      // Create a CatalogItem instance with test data including height
      final catalogItem = tabbedSections;
      final data = {
        'sections': [
          {'title': 'Tab 1', 'child': 'child1'},
        ],
        'height': 200.0,
      };

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (context) {
                    return catalogItem.widgetBuilder(
                      data: data,
                      id: 'test_tabbed_sections_height',
                      buildChild: mockBuildChild,
                      dispatchEvent: (event) {},
                      context: context,
                      values: {},
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Verify that the SizedBox with the specified height is present
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 200.0,
        ),
        findsOneWidget,
      );

      // Verify that the content is displayed
      expect(find.text('Content'), findsOneWidget);
    });
  });
}
