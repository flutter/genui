// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('DebugCatalogView', () {
    // https://github.com/flutter/genui/issues/671
    testWidgets('Renders a custom Catalog', (WidgetTester tester) async {
      final expectedText = 'This Test Is Working!!';
      final testCatalog = Catalog([
        getTextForTesting(expectedText),
      ], catalogId: 'some-catalog-id-for-testing');

      await tester.pumpWidget(
        MaterialApp(
          home: DebugCatalogView(catalog: testCatalog),
        ),
      );

      expect(find.text(expectedText), findsOneWidget);
    });
  });
}

/// Returns a simple fork of the core Text catalog item that renders the
/// incoming [successMessage].
CatalogItem getTextForTesting(String successMessage) => CatalogItem(
  name: 'TextForTesting',
  dataSchema: CoreCatalogItems.text.dataSchema,
  widgetBuilder: CoreCatalogItems.text.widgetBuilder,
  exampleData: [
    () =>
        '''
      [
        {
          "id": "root",
          "component": {
            "TextForTesting": {
              "text": {
                "literalString": "$successMessage"
              }
            }
          }
        }
      ]
    ''',
  ],
);
