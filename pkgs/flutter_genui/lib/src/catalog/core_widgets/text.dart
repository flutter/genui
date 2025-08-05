// ignore_for_file: avoid_dynamic_calls

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import '../../model/catalog_item.dart';

extension type _TextData.fromMap(Map<String, Object?> _json) {
  factory _TextData({required String text}) =>
      _TextData.fromMap({'text': text});

  String get text => _json['text'] as String;
}

final text = CatalogItem(
  name: 'text',
  dataSchema: Schema.object(
    properties: {
      'text': Schema.string(
        description: 'The text to display. This does *not* support markdown.',
      ),
    },
  ),
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final textData = _TextData.fromMap(data as Map<String, Object?>);
        return Text(
          textData.text,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
);
