// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/options_filter_chip.dart';

void main() {
  group('optionsFilterChip', () {
    testWidgets('renders correctly and handles selection with an icon', (
      WidgetTester tester,
    ) async {
      final data = {
        'chipLabel': 'Price',
        'options': ['\$', '\$\$', '\$\$\$'],
        'iconChild': 'iconId',
      };

      UiEvent? dispatchedEvent;
      Widget buildChild(String id) {
        if (id == 'iconId') {
          return const Icon(Icons.attach_money);
        }
        return const SizedBox.shrink();
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return optionsFilterChip.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: buildChild,
                  dispatchEvent: (event) {
                    dispatchedEvent = event;
                  },
                  context: context,
                  values: {},
                );
              },
            ),
          ),
        ),
      );

      // Check initial state.
      expect(find.byType(FilterChip), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);

      // Tap the chip to open the modal bottom sheet.
      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();

      // Check if the bottom sheet is shown with options.
      expect(find.byType(RadioListTile<String>), findsNWidgets(3));
      expect(find.text('\$'), findsOneWidget);
      expect(find.text('\$\$'), findsOneWidget);
      expect(find.text('\$\$\$'), findsOneWidget);

      // Tap an option
      await tester.tap(find.text('\$\$').last);
      await tester.pumpAndSettle();

      // Check if the bottom sheet is closed.
      expect(find.byType(RadioListTile<String>), findsNothing);

      // Check if the chip label is updated.
      expect(find.text('\$\$'), findsOneWidget);

      // Check if the event was dispatched.
      expect(dispatchedEvent, isA<UiChangeEvent>());
      final changeEvent = dispatchedEvent as UiChangeEvent;
      expect(changeEvent.widgetId, 'testId');
      expect(changeEvent.eventType, 'filterOptionSelected');
      expect(changeEvent.value, '\$\$');
    });

    testWidgets('renders correctly and handles selection without an icon', (
      WidgetTester tester,
    ) async {
      final data = {
        'chipLabel': 'Price',
        'options': ['\$', '\$\$', '\$\$\$'],
      };

      UiEvent? dispatchedEvent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return optionsFilterChip.widgetBuilder(
                  data: data,
                  id: 'testId',
                  buildChild: (_) => const SizedBox.shrink(),
                  dispatchEvent: (event) {
                    dispatchedEvent = event;
                  },
                  context: context,
                  values: {},
                );
              },
            ),
          ),
        ),
      );

      // Check initial state.
      expect(find.byType(FilterChip), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);

      // Tap the chip to open the modal bottom sheet.
      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();

      // Tap an option.
      await tester.tap(find.text('\$\$\$').last);
      await tester.pumpAndSettle();

      // Check if the chip label is updated.
      expect(find.text('\$\$\$'), findsOneWidget);

      // Check if the event was dispatched.
      expect(dispatchedEvent, isA<UiChangeEvent>());
      final changeEvent = dispatchedEvent as UiChangeEvent;
      expect(changeEvent.widgetId, 'testId');
      expect(changeEvent.eventType, 'filterOptionSelected');
      expect(changeEvent.value, '\$\$\$');
    });
  });
}
