// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:travel_app/src/catalog/checkbox_filter_chips_input.dart';

void main() {
  testWidgets('CheckboxFilterChipsInput widget test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: checkboxFilterChipsInput.widgetBuilder(
                  CatalogItemContext(
                    getCatalogItem: (type) => null,
                    data: {
                      'chipLabel': 'Amenities',
                      'options': ['Wifi', 'Pool', 'Gym'],
                      'selectedOptions': ['Wifi', 'Gym'],
                      'iconName': 'hotel',
                    },
                    id: 'test',
                    type: 'CheckboxFilterChipsInput',
                    buildChild: (_, [_]) => const SizedBox(),
                    dispatchEvent: (_) {},
                    buildContext: context,
                    dataContext: DataContext(DataModel(), '/'),
                    getComponent: (String componentId) => null,
                    surfaceId: 'surface1',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Wifi, Gym'), findsOneWidget);
  });

  testWidgets(
    'CheckboxFilterChipsInput updates DataContext with implicit binding',
    (WidgetTester tester) async {
      final dataModel = DataModel();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: checkboxFilterChipsInput.widgetBuilder(
                    CatalogItemContext(
                      getCatalogItem: (type) => null,
                      data: {
                        'chipLabel': 'Amenities',
                        'options': ['Wifi', 'Pool', 'Gym'],
                        'selectedOptions': ['Wifi'],
                        'iconName': 'hotel',
                      },
                      id: 'test',
                      type: 'CheckboxFilterChipsInput',
                      buildChild: (_, [_]) => const SizedBox(),
                      dispatchEvent: (_) {},
                      buildContext: context,
                      dataContext: DataContext(dataModel, '/'),
                      getComponent: (String componentId) => null,
                      surfaceId: 'surface1',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Wifi'), findsOneWidget);
      expect(dataModel.getValue<Object?>(DataPath('test.value')), isNull);

      // Open the modal
      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();

      // Select 'Pool'
      await tester.tap(find.text('Pool'));
      await tester.pump();

      // Update happens immediately on selection change in the modal
      final value =
          dataModel.getValue(DataPath('test.value')) as List<Object?>?;
      expect(value, containsAll(['Wifi', 'Pool']));
    },
  );
}
