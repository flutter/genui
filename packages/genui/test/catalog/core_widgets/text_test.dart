// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/src/catalog/core_widgets/text.dart';
import 'package:genui/src/model/catalog_item.dart';
import 'package:genui/src/model/data_model.dart';
import 'package:genui/src/model/ui_models.dart';

void main() {
  testWidgets('Text widget renders literal string', (
    WidgetTester tester,
  ) async {
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

  testWidgets('Text widget renders with h1 usage hint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: text.widgetBuilder(
              CatalogItemContext(
                data: {
                  'text': {'literalString': 'Heading 1'},
                  'usageHint': 'h1',
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

    // MarkdownBody renders RichText, so find.text still works for simple text.
    final Finder textFinder = find.text('Heading 1');
    expect(textFinder, findsOneWidget);

    // Verify padding
    final Finder paddingFinder = find.ancestor(
      of: textFinder,
      matching: find.byType(Padding),
    );
    expect(paddingFinder, findsOneWidget);
    final Padding paddingWidget = tester.widget<Padding>(paddingFinder);
    expect(paddingWidget.padding, const EdgeInsets.symmetric(vertical: 20.0));

    // Verify MarkdownBody is present
    final Finder markdownBodyFinder = find.byType(MarkdownBody);
    expect(markdownBodyFinder, findsOneWidget);
    final MarkdownBody markdownBody = tester.widget<MarkdownBody>(
      markdownBodyFinder,
    );

    // Verify data
    expect(markdownBody.data, 'Heading 1');

    // Verify styleSheet has correct p style
    final Element context = tester.element(textFinder);
    final TextStyle? expectedStyle = Theme.of(context).textTheme.headlineLarge;
    expect(markdownBody.styleSheet?.p?.fontSize, expectedStyle?.fontSize);
  });

  testWidgets('Text widget renders markdown bold', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: text.widgetBuilder(
              CatalogItemContext(
                data: {
                  'text': {'literalString': 'Hello **Bold**'},
                },
                id: 'test_text_markdown',
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

    // We can verify that MarkdownBody is present and has the correct data.
    expect(find.byType(MarkdownBody), findsOneWidget);
    final MarkdownBody markdownBody = tester.widget<MarkdownBody>(
      find.byType(MarkdownBody),
    );
    expect(markdownBody.data, 'Hello **Bold**');

    // Flutter test `find.text` matches the whole string.
    // `find.textContaining` matches substring.
    expect(find.textContaining('Bold', findRichText: true), findsOneWidget);
  });

  testWidgets('Text widget respects ambient DefaultTextStyle color', (
    WidgetTester tester,
  ) async {
    const Color requiredColor = Colors.red;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: DefaultTextStyle(
              style: const TextStyle(color: requiredColor),
              child: text.widgetBuilder(
                CatalogItemContext(
                  data: {
                    'text': {'literalString': 'Contrast Text'},
                  },
                  id: 'test_contrast',
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
      ),
    );

    final Finder markdownBodyFinder = find.byType(MarkdownBody);
    final MarkdownBody markdownBody = tester.widget<MarkdownBody>(
      markdownBodyFinder,
    );
    expect(markdownBody.styleSheet?.p?.color, requiredColor);

    final RichText richText = tester.widget(
      find
          .descendant(of: markdownBodyFinder, matching: find.byType(RichText))
          .first,
    );
    expect(richText.text.style?.color, requiredColor);
  });
}
