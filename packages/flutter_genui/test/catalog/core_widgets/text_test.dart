// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/src/catalog/core_widgets/text.dart';
import 'package:flutter_genui/src/model/catalog_item.dart';
import 'package:flutter_genui/src/model/data_model.dart';
import 'package:flutter_genui/src/model/ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Text widget renders literal string', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: text.widgetBuilder(
              CatalogItemContext(
                data: {
                  'text': {'literalString': 'Hello World'},
                },
                id: 'test_text',
                buildChild: (_, [_]) => const SizedBox(),
                dispatchEvent: (UiEvent event) {},
                buildContext: context,
                dataContext: DataContext(DataModel(), '/'),
                getComponent: (String componentId) => null,
                surfaceId: 'surface1',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hello World'), findsOneWidget);
  });

  testWidgets('Text widget renders with h1 hint', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: text.widgetBuilder(
              CatalogItemContext(
                data: {
                  'text': {'literalString': 'Heading 1'},
                  'hint': 'h1',
                },
                id: 'test_text_h1',
                buildChild: (_, [_]) => const SizedBox(),
                dispatchEvent: (UiEvent event) {},
                buildContext: context,
                dataContext: DataContext(DataModel(), '/'),
                getComponent: (String componentId) => null,
                surfaceId: 'surface1',
              ),
            ),
          ),
        ),
      ),
    );

    final textFinder = find.text('Heading 1');
    expect(textFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(textFinder);
    final context = tester.element(textFinder);
    final expectedStyle = Theme.of(context).textTheme.headlineLarge;
    expect(textWidget.style, expectedStyle);

    final paddingFinder = find.ancestor(
      of: textFinder,
      matching: find.byType(Padding),
    );
    expect(paddingFinder, findsOneWidget);
    final paddingWidget = tester.widget<Padding>(paddingFinder);
    expect(
      paddingWidget.padding,
      const EdgeInsets.symmetric(vertical: 20.0),
    );
  });

  testWidgets('Text widget renders with caption hint', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: text.widgetBuilder(
              CatalogItemContext(
                data: {
                  'text': {'literalString': 'Caption Text'},
                  'hint': 'caption',
                },
                id: 'test_text_caption',
                buildChild: (_, [_]) => const SizedBox(),
                dispatchEvent: (UiEvent event) {},
                buildContext: context,
                dataContext: DataContext(DataModel(), '/'),
                getComponent: (String componentId) => null,
                surfaceId: 'surface1',
              ),
            ),
          ),
        ),
      ),
    );

    final textFinder = find.text('Caption Text');
    expect(textFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(textFinder);
    final context = tester.element(textFinder);
    final expectedStyle = Theme.of(context).textTheme.bodySmall;
    expect(textWidget.style, expectedStyle);
  });
}
