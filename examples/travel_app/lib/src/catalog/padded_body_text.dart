// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../utils.dart';

extension type _PaddedBodyTextData.fromMap(Map<String, Object?> _json) {
  factory _PaddedBodyTextData({required JsonMap text}) =>
      _PaddedBodyTextData.fromMap({'text': text});

  JsonMap get text => _json['text'] as JsonMap;
}

final paddedBodyText = CatalogItem(
  name: 'PaddedBodyText',
  dataSchema: S.object(
    properties: {
      'text': A2uiSchemas.stringReference(
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
        required dataContext,
      }) {
        final textData = _PaddedBodyTextData.fromMap(
          data as Map<String, Object?>,
        );

        final notifier = dataContext.subscribeToString(textData.text);

        return ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, text, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MarkdownWidget(text: text ?? ''),
            );
          },
        );
      },
);
