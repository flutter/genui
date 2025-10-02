// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/catalog_item.dart';
import '../../model/ui_models.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'child': S.string(
      description:
          'The ID of a child widget. This should always be set, e.g. to the ID '
          'of a `Text` widget.',
    ),
    'action': S.string(
      description:
          'A short description of what should happen when the button is '
          'pressed to be used by the LLM.',
    ),
  },
  required: ['child'],
);

extension type _ElevatedButtonData.fromMap(JsonMap _json) {
  factory _ElevatedButtonData({required String child, String? action}) =>
      _ElevatedButtonData.fromMap({'child': child, 'action': action});

  String get child => _json['child'] as String;
  String? get action => _json['action'] as String?;
}

final elevatedButton = CatalogItem(
  name: 'ElevatedButton',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final buttonData = _ElevatedButtonData.fromMap(data as JsonMap);
        final child = buildChild(buttonData.child);
        return ElevatedButton(
          onPressed: () => dispatchEvent(
            UiActionEvent(
              widgetId: id,
              eventType: 'onTap',
              value: buttonData.action,
            ),
          ),
          child: child,
        );
      },
);
