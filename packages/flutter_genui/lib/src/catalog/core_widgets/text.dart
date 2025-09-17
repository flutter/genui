// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';

extension type _TextData.fromMap(JsonMap _json) {
  factory _TextData({required String text}) =>
      _TextData.fromMap({'text': text});

  String get text => _json['text'] as String;
}

final text = CatalogItem(
  name: 'Text',
  dataSchema: S.object(
    properties: {
      'text': S.string(
        description: 'The text to display. This does *not* support markdown.',
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
        final textData = _TextData.fromMap(data as JsonMap);
        return Text(
          textData.text,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
);
