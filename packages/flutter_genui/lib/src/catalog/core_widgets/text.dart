// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

extension type _TextData.fromMap(JsonMap _json) {
  factory _TextData({required JsonMap text, String? hint}) =>
      _TextData.fromMap({'text': text, 'hint': hint});

  JsonMap get text => _json['text'] as JsonMap;
  String? get hint => _json['hint'] as String?;
}

/// A catalog item representing a block of styled text.
///
/// This widget displays a string of text, analogous to Flutter's [Text] widget.
/// The content is taken from the `text` parameter, which can be a literal
/// string or a data model binding.
///
/// ## Parameters:
///
/// - `text`: The text to display. This supports markdown.
/// - `hint`: A hint for the text style. One of 'h1', 'h2', 'h3', 'h4', 'h5',
///   'caption', 'body'.
final text = CatalogItem(
  name: 'Text',
  dataSchema: S.object(
    properties: {
      'text': A2uiSchemas.stringReference(
        description:
            '''While simple Markdown is supported (without HTML or image references), utilizing dedicated UI components is generally preferred for a richer and more structured presentation.''',
      ),
      'hint': S.string(
        description: 'A hint for the base text style.',
        enumValues: ['h1', 'h2', 'h3', 'h4', 'h5', 'caption', 'body'],
      ),
    },
    required: ['text'],
  ),
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Text": {
              "text": {
                "literalString": "Hello World"
              },
              "hint": "h1"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final textData = _TextData.fromMap(itemContext.data as JsonMap);
    final ValueNotifier<String?> notifier = itemContext.dataContext
        .subscribeToString(textData.text);

    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, currentValue, child) {
        final TextTheme textTheme = Theme.of(context).textTheme;
        final String hint = textData.hint ?? 'body';
        final TextStyle? baseStyle = switch (hint) {
          'h1' => textTheme.headlineLarge,
          'h2' => textTheme.headlineMedium,
          'h3' => textTheme.headlineSmall,
          'h4' => textTheme.titleLarge,
          'h5' => textTheme.titleMedium,
          'caption' => textTheme.bodySmall,
          _ => textTheme.bodyMedium,
        };
        final double verticalPadding = switch (hint) {
          'h1' => 20.0,
          'h2' => 16.0,
          'h3' => 12.0,
          'h4' => 8.0,
          'h5' => 4.0,
          _ => 0.0,
        };

        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: MarkdownBody(
            data: currentValue ?? '',
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(p: baseStyle),
          ),
        );
      },
    );
  },
);
