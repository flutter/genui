// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/ui_models.dart';
import '../../primitives/logging.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'child': A2uiSchemas.componentReference(
      description:
          'The ID of a child widget. This should always be set, e.g. to the ID '
          'of a `Text` widget.',
    ),
    'action': A2uiSchemas.action(),
    'primary': S.boolean(
      description: 'Whether the button invokes a primary action.',
    ),
  },
  required: ['child', 'action'],
);

extension type _ButtonData.fromMap(JsonMap _json) {
  factory _ButtonData({
    required String child,
    required JsonMap action,
    bool primary = false,
  }) => _ButtonData.fromMap({
    'child': child,
    'action': action,
    'primary': primary,
  });

  String get child => _json['child'] as String;
  JsonMap get action => _json['action'] as JsonMap;
  bool get primary => (_json['primary'] as bool?) ?? false;
}

/// A catalog item representing a Material Design elevated button.
///
/// This widget displays an interactive button. When pressed, it dispatches
/// the specified `action` event. The button's appearance can be styled as
/// a primary action.
///
/// ## Parameters:
///
/// - `child`: The ID of a child widget to display inside the button.
/// - `action`: The action to perform when the button is pressed.
/// - `primary`: Whether the button invokes a primary action (defaults to
///   false).
final button = CatalogItem(
  name: 'Button',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final buttonData = _ButtonData.fromMap(data as JsonMap);
        final child = buildChild(buttonData.child);
        final actionData = buttonData.action;
        final actionName = actionData['name'] as String;
        final contextDefinition =
            (actionData['context'] as List<Object?>?) ?? <Object?>[];

        genUiLogger.info('Building Button with child: ${buttonData.child}');
        final colorScheme = Theme.of(context).colorScheme;
        final primary = buttonData.primary;

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary
                ? colorScheme.primary
                : colorScheme.surface,
            foregroundColor: primary
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
          ),
          onPressed: () {
            final resolvedContext = resolveContext(
              dataContext,
              contextDefinition,
            );
            dispatchEvent(
              UserActionEvent(
                name: actionName,
                sourceComponentId: id,
                context: resolvedContext,
              ),
            );
          },
          child: child,
        );
      },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Button": {
              "child": "text",
              "action": {
                "name": "button_pressed"
              }
            }
          }
        },
        {
          "id": "text",
          "component": {
            "Text": {
              "text": {
                "literalString": "Hello World"
              }
            }
          }
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": {
            "Column": {
              "children": {
                "explicitList": ["primaryButton", "secondaryButton"]
              }
            }
          }
        },
        {
          "id": "primaryButton",
          "component": {
            "Button": {
              "child": "primaryText",
              "primary": true,
              "action": {
                "name": "primary_pressed"
              }
            }
          }
        },
        {
          "id": "secondaryButton",
          "component": {
            "Button": {
              "child": "secondaryText",
              "action": {
                "name": "secondary_pressed"
              }
            }
          }
        },
        {
          "id": "primaryText",
          "component": {
            "Text": {
              "text": {
                "literalString": "Primary Button"
              }
            }
          }
        },
        {
          "id": "secondaryText",
          "component": {
            "Text": {
              "text": {
                "literalString": "Secondary Button"
              }
            }
          }
        }
      ]
    ''',
  ],
);
