// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../functions/expression_parser.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/ui_models.dart';
import '../../primitives/logging.dart';
import '../../primitives/simple_items.dart';
import '../../widgets/widget_utilities.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['Button']),
    'child': A2uiSchemas.componentReference(
      description:
          'The ID of a child widget. This should always be set, e.g. to the ID '
          'of a `Text` widget.',
    ),
    'action': A2uiSchemas.action(),
    'variant': S.string(
      description: 'A hint for the button style.',
      enumValues: ['primary', 'borderless'],
    ),
  },
  required: ['component', 'child', 'action'],
);

extension type _ButtonData.fromMap(JsonMap _json) {
  factory _ButtonData({
    required String child,
    required JsonMap action,
    String? variant,
  }) => _ButtonData.fromMap({
    'child': child,
    'action': action,
    'variant': variant,
  });

  String get child {
    final Object? val = _json['child'];
    if (val is String) return val;
    if (val is JsonMap && val.containsKey('literalString')) {
      return val['literalString'] as String;
    }
    throw ArgumentError('Invalid child: $val');
  }

  JsonMap get action => _json['action'] as JsonMap;
  String? get variant => _json['variant'] as String?;
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
/// - `variant`: A hint for the button style ('primary' or 'borderless').
final button = CatalogItem(
  name: 'Button',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final buttonData = _ButtonData.fromMap(itemContext.data as JsonMap);
    final Widget child = itemContext.buildChild(buttonData.child);
    genUiLogger.info('Building Button with child: ${buttonData.child}');
    final ColorScheme colorScheme = Theme.of(
      itemContext.buildContext,
    ).colorScheme;
    final String variant = buttonData.variant ?? '';
    final primary = variant == 'primary';
    final borderless = variant == 'borderless';

    final TextStyle? textStyle = Theme.of(itemContext.buildContext)
        .textTheme
        .bodyLarge
        ?.copyWith(
          color: primary ? colorScheme.onPrimary : colorScheme.onSurface,
        );

    final ButtonStyle style = switch (variant) {
      'primary' => ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      'borderless' => TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
      ),
      _ => ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    };

    final Widget buttonWidget = borderless
        ? TextButton(
            onPressed: () => _handlePress(itemContext, buttonData),
            child: child,
          )
        : ElevatedButton(
            style: style.copyWith(textStyle: WidgetStatePropertyAll(textStyle)),
            onPressed: () => _handlePress(itemContext, buttonData),
            child: child,
          );

    return buttonWidget;
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Button",
          "child": "text",
          "action": {
            "event": {
              "name": "button_pressed"
            }
          }
        },
        {
          "id": "text",
          "component": "Text",
          "text": "Hello World"
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": "Column",
          "children": ["primaryButton", "secondaryButton"]
        },
        {
          "id": "primaryButton",
          "component": "Button",
          "child": "primaryText",
          "primary": true,
          "action": {
            "event": {
              "name": "primary_pressed"
            }
          }
        },
        {
          "id": "secondaryButton",
          "component": "Button",
          "child": "secondaryText",
          "action": {
            "event": {
              "name": "secondary_pressed"
            }
          }
        },
        {
          "id": "primaryText",
          "component": "Text",
          "text": "Primary Button"
        },
        {
          "id": "secondaryText",
          "component": "Text",
          "text": "Secondary Button"
        }
      ]
    ''',
  ],
);

void _handlePress(CatalogItemContext itemContext, _ButtonData buttonData) {
  final JsonMap actionData = buttonData.action;
  if (actionData.containsKey('event')) {
    final eventMap = actionData['event'] as JsonMap;
    final actionName = eventMap['name'] as String;
    final contextDefinition = eventMap['context'] as JsonMap?;

    final JsonMap resolvedContext = resolveContext(
      itemContext.dataContext,
      contextDefinition,
    );
    itemContext.dispatchEvent(
      UserActionEvent(
        name: actionName,
        sourceComponentId: itemContext.id,
        context: resolvedContext,
      ),
    );
  } else if (actionData.containsKey('functionCall')) {
    final funcMap = actionData['functionCall'] as JsonMap;
    final callName = funcMap['call'] as String;

    if (callName == 'closeModal') {
      Navigator.of(itemContext.buildContext).pop();
      return;
    }

    final parser = ExpressionParser(itemContext.dataContext);
    parser.evaluateFunctionCall(funcMap);
  } else {
    genUiLogger.warning(
      'Button action missing event or functionCall: $actionData',
    );
  }
}
