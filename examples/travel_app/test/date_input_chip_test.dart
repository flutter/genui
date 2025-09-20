// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:travel_app/src/catalog/date_input_chip.dart';

void main() {
  testWidgets('DateInputChip catalog item builds and responds to taps', (
    WidgetTester tester,
  ) async {
    final values = <String, Object?>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return dateInputChip.widgetBuilder(
                data: {'value': '2025-09-20', 'label': 'Test Date'},
                id: 'test_chip',
                buildChild: (data) => const SizedBox(),
                dispatchEvent: (event) {},
                context: context,
                values: values,
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Test Date: Sep 20, 2025'), findsOneWidget);

    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);

    // Tap on the 10th of the month.
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    expect(values['test_chip'], '2025-09-10');

    expect(find.text('Test Date: Sep 10, 2025'), findsOneWidget);
  });

  testWidgets('DateInputChip selects date when no initial value', (
    WidgetTester tester,
  ) async {
    final values = <String, Object?>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return dateInputChip.widgetBuilder(
                data: {'label': 'Test Date'},
                id: 'test_chip',
                buildChild: (data) => const SizedBox(),
                dispatchEvent: (event) {},
                context: context,
                values: values,
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Test Date'), findsOneWidget);

    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);

    // Tap on the 10th of the month.
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final expectedDate = DateTime(now.year, now.month, 10);
    final formatted =
        '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}'
        '-10';
    expect(values['test_chip'], formatted);

    final month = DateFormat.MMM().format(expectedDate);
    expect(
      find.text('Test Date: $month 10, ${expectedDate.year}'),
      findsOneWidget,
    );
  });
}
