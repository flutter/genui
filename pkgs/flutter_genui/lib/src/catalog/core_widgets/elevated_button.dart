// ignore_for_file: avoid_dynamic_calls

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';

final _schema = Schema.object(
  properties: {
    'child': Schema.string(
      description:
          '''The ID of a child widget. This should always be set, e.g. to a `text`.''',
    ),
  },
);

extension type _ElevatedButtonData.fromMap(Map<String, Object?> _json) {
  factory _ElevatedButtonData({required String child}) =>
      _ElevatedButtonData.fromMap({'child': child});

  String get child => _json['child'] as String;
}

final elevatedButtonCatalogItem = CatalogItem(
  name: 'elevated_button',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final buttonData = _ElevatedButtonData.fromMap(
          data as Map<String, Object?>,
        );
        final child = buildChild(buttonData.child);
        return ElevatedButton(
          onPressed: () =>
              dispatchEvent(widgetId: id, eventType: 'onTap', value: null),
          child: child,
        );
      },
);
