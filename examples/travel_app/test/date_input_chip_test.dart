// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:intl/intl.dart';
import 'package:travel_app/src/catalog/date_input_chip.dart';

void main() {
  testWidgets('DateInputChip catalog item builds with literal value', (
    WidgetTester tester,
  ) async {
    final dataModel = DataModel();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return dateInputChip.widgetBuilder(
                CatalogItemContext(
                  getCatalogItem: (type) => null,
                  data: {'value': '2025-09-20', 'label': 'Test Date'},
                  id: 'test_chip',
                  type: 'DateInputChip',
                  buildChild: (data, [_]) => const SizedBox(),
                  dispatchEvent: (event) {},
                  buildContext: context,
                  dataContext: DataContext(dataModel, '/'),
                  getComponent: (String componentId) => null,
                  surfaceId: 'surface1',
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Test Date: Sep 20, 2025'), findsOneWidget);
  });

  testWidgets('DateInputChip catalog item builds with data model value', (
    WidgetTester tester,
  ) async {
    final dataModel = DataModel();
    dataModel.update(DataPath('/testDate'), '2025-09-20');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return dateInputChip.widgetBuilder(
                CatalogItemContext(
                  getCatalogItem: (type) => null,
                  data: {
                    'value': {'path': '/testDate'},
                    'label': 'Test Date',
                  },
                  id: 'test_chip',
                  type: 'DateInputChip',
                  buildChild: (data, [_]) => const SizedBox(),
                  dispatchEvent: (event) {},
                  buildContext: context,
                  dataContext: DataContext(dataModel, '/'),
                  getComponent: (String componentId) => null,
                  surfaceId: 'surface1',
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Test Date: Sep 20, 2025'), findsOneWidget);

    // Update the data model and expect the UI to change
    dataModel.update(DataPath('/testDate'), '2025-10-15');
    await tester.pump();
    expect(find.text('Test Date: Oct 15, 2025'), findsOneWidget);
  });

  testWidgets('DateInputChip updates data model on date selection', (
    WidgetTester tester,
  ) async {
    final dataModel = DataModel();
    dataModel.update(DataPath('/testDate'), '2025-09-20');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return dateInputChip.widgetBuilder(
                CatalogItemContext(
                  getCatalogItem: (type) => null,
                  data: {
                    'value': {'path': '/testDate'},
                    'label': 'Test Date',
                  },
                  id: 'test_chip',
                  type: 'DateInputChip',
                  buildChild: (data, [_]) => const SizedBox(),
                  dispatchEvent: (event) {},
                  buildContext: context,
                  dataContext: DataContext(dataModel, '/'),
                  getComponent: (String componentId) => null,
                  surfaceId: 'surface1',
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    expect(dataModel.getValue<String>(DataPath('/testDate')), '2025-09-10');
    expect(find.text('Test Date: Sep 10, 2025'), findsOneWidget);
  });

  testWidgets('DateInputChip selects date when no initial value', (
    WidgetTester tester,
  ) async {
    final dataModel = DataModel();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return dateInputChip.widgetBuilder(
                CatalogItemContext(
                  getCatalogItem: (type) => null,
                  data: {
                    'value': {'path': '/testDate'},
                    'label': 'Test Date',
                  },
                  id: 'test_chip',
                  type: 'DateInputChip',
                  buildChild: (data, [_]) => const SizedBox(),
                  dispatchEvent: (event) {},
                  buildContext: context,
                  dataContext: DataContext(dataModel, '/'),
                  getComponent: (String componentId) => null,
                  surfaceId: 'surface1',
                ),
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
        '${expectedDate.year}-'
        '${expectedDate.month.toString().padLeft(2, '0')}-10';
    expect(dataModel.getValue<String>(DataPath('/testDate')), formatted);

    final String month = DateFormat.MMM().format(expectedDate);
    expect(
      find.text('Test Date: $month 10, ${expectedDate.year}'),
      findsOneWidget,
    );
  });
  testWidgets(
    'DateInputChip updates implicit data model path on date selection when '
    'initialized with literal',
    (WidgetTester tester) async {
      final dataModel = DataModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return dateInputChip.widgetBuilder(
                  CatalogItemContext(
                    getCatalogItem: (type) => null,
                    data: {'value': '2025-09-20', 'label': 'Test Date'},
                    id: 'test_chip_implicit',
                    type: 'DateInputChip',
                    buildChild: (data, [_]) => const SizedBox(),
                    dispatchEvent: (event) {},
                    buildContext: context,
                    dataContext: DataContext(dataModel, '/'),
                    getComponent: (String componentId) => null,
                    surfaceId: 'surface1',
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Date: Sep 20, 2025'), findsOneWidget);

      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();

      // Verify update to implicit path: test_chip_implicit.value
      expect(
        dataModel.getValue<String>(DataPath('test_chip_implicit.value')),
        '2025-09-10',
      );
      expect(find.text('Test Date: Sep 10, 2025'), findsOneWidget);
    },
  );
}
