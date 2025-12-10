// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  testWidgets('MultipleChoice widget renders and handles changes', (
    WidgetTester tester,
  ) async {
    final manager = GenUiManager(
      catalogs: [
        Catalog([
          CoreCatalogItems.choicePicker,
          CoreCatalogItems.text,
        ], catalogId: standardCatalogId),
      ],
    );
    const surfaceId = 'testSurface';
    final components = [
      const Component(
        id: 'root',
        props: {
          'component': 'ChoicePicker',
          'value': {'path': '/mySelections'},
          'options': {
            'literalArray': [
              {
                'label': {'literalString': 'Option 1'},
                'value': '1',
              },
              {
                'label': {'literalString': 'Option 2'},
                'value': '2',
              },
            ],
          },
        },
      ),
    ];
    manager.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: components),
    );
    manager.handleMessage(
      const CreateSurface(surfaceId: surfaceId, catalogId: standardCatalogId),
    );
    manager.dataModelForSurface(surfaceId).update(DataPath('/mySelections'), [
      '1',
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenUiSurface(host: manager, surfaceId: surfaceId),
        ),
      ),
    );

    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('Option 2'), findsOneWidget);
    final CheckboxListTile checkbox1 = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect(checkbox1.value, isTrue);
    final CheckboxListTile checkbox2 = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).last,
    );
    expect(checkbox2.value, isFalse);

    await tester.tap(find.text('Option 2'));
    expect(
      manager
          .dataModelForSurface(surfaceId)
          .getValue<List<Object?>>(DataPath('/mySelections')),
      ['1', '2'],
    );
  });

  testWidgets(
    'MultipleChoice widget handles simple string labels from data model',
    (WidgetTester tester) async {
      final manager = GenUiManager(
        catalogs: [
          Catalog([
            CoreCatalogItems.choicePicker,
          ], catalogId: standardCatalogId),
        ],
      );
      const surfaceId = 'testSurfaceSimple';
      final components = [
        const Component(
          id: 'root',
          props: {
            'component': 'ChoicePicker',
            'value': {'path': '/mySelections'},
            'options': {'path': '/myOptions'},
          },
        ),
      ];
      manager.handleMessage(
        UpdateComponents(surfaceId: surfaceId, components: components),
      );
      manager.handleMessage(
        const CreateSurface(surfaceId: surfaceId, catalogId: standardCatalogId),
      );
      manager.handleMessage(
        const UpdateDataModel(
          surfaceId: surfaceId,
          value: {
            'mySelections': <String>[],
            'myOptions': [
              {'label': 'Simple Option 1', 'value': 's1'},
              {'label': 'Simple Option 2', 'value': 's2'},
            ],
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenUiSurface(host: manager, surfaceId: surfaceId),
          ),
        ),
      );

      expect(find.text('Simple Option 1'), findsOneWidget);
      expect(find.text('Simple Option 2'), findsOneWidget);
    },
  );
}
