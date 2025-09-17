// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../utils.dart';

extension type _PaddedBodyTextData.fromMap(Map<String, Object?> _json) {
  factory _PaddedBodyTextData({required String text}) =>
      _PaddedBodyTextData.fromMap({'text': text});

  String get text => _json['text'] as String;
}

final paddedBodyText = CatalogItem(
  name: 'PaddedBodyText',
  dataSchema: S.object(
    properties: {
      'text': S.string(
        description: 'The text to display. This supports markdown.',
      ),
    },
    required: ['text'],
  ),
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final textData = _PaddedBodyTextData.fromMap(
          data as Map<String, Object?>,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: MarkdownBody(
            data: textData.text,
            styleSheet: getMarkdownStyleSheet(context),
          ),
        );
      },
);
