// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../model/ui_models.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  description: 'A text input field.',
  properties: {
    'text': A2uiSchemas.stringReference(
      description: 'The initial value of the text field.',
    ),
    'label': A2uiSchemas.stringReference(),
    'textFieldType': S.string(
      enumValues: ['shortText', 'longText', 'number', 'date', 'obscured'],
    ),
    'validationRegexp': S.string(),
    'onSubmittedAction': A2uiSchemas.action(),
  },
);

extension type _TextFieldData.fromMap(JsonMap _json) {
  factory _TextFieldData({
    JsonMap? text,
    JsonMap? label,
    String? textFieldType,
    String? validationRegexp,
    JsonMap? onSubmittedAction,
  }) => _TextFieldData.fromMap({
    'text': text,
    'label': label,
    'textFieldType': textFieldType,
    'validationRegexp': validationRegexp,
    'onSubmittedAction': onSubmittedAction,
  });

  JsonMap? get text => _json['text'] as JsonMap?;
  JsonMap? get label => _json['label'] as JsonMap?;
  String? get textFieldType => _json['textFieldType'] as String?;
  String? get validationRegexp => _json['validationRegexp'] as String?;
  JsonMap? get onSubmittedAction => _json['onSubmittedAction'] as JsonMap?;
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.initialValue,
    this.label,
    this.textFieldType,
    this.validationRegexp,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String initialValue;
  final String? label;
  final String? textFieldType;
  final String? validationRegexp;
  final void Function(String) onChanged;
  final void Function(String) onSubmitted;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label),
      obscureText: widget.textFieldType == 'obscured',
      keyboardType: switch (widget.textFieldType) {
        'number' => TextInputType.number,
        'longText' => TextInputType.multiline,
        'date' => TextInputType.datetime,
        _ => TextInputType.text,
      },
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}

/// A catalog item representing a Material Design text field.
///
/// This widget allows the user to enter and edit text. The `text` parameter
/// bidirectionally binds the field's content to the data model. This is
/// analogous to Flutter's [TextField] widget.
///
/// ## Parameters:
///
/// - `text`: The initial value of the text field.
/// - `label`: The text to display as the label for the text field.
/// - `textFieldType`: The type of text field. Can be `shortText`, `longText`,
///   `number`, `date`, or `obscured`.
/// - `validationRegexp`: A regular expression to validate the input.
/// - `onSubmittedAction`: The action to perform when the user submits the
///   text field.
final textField = CatalogItem(
  name: 'TextField',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": {
            "TextField": {
              "text": {
                "literalString": "Hello World"
              },
              "label": {
                "literalString": "Greeting"
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
            "TextField": {
              "text": {
                "literalString": "password123"
              },
              "label": {
                "literalString": "Password"
              },
              "textFieldType": "obscured"
            }
          }
        }
      ]
    ''',
  ],
  widgetBuilder: (itemContext) {
    final textFieldData = _TextFieldData.fromMap(itemContext.data as JsonMap);
    final JsonMap? valueRef = textFieldData.text;
    final path = valueRef?['path'] as String?;
    final ValueNotifier<String?> notifier = itemContext.dataContext
        .subscribeToString(valueRef);
    final ValueNotifier<String?> labelNotifier = itemContext.dataContext
        .subscribeToString(textFieldData.label);

    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (context, currentValue, child) {
        return ValueListenableBuilder(
          valueListenable: labelNotifier,
          builder: (context, label, child) {
            return _TextField(
              initialValue: currentValue ?? '',
              label: label,
              textFieldType: textFieldData.textFieldType,
              validationRegexp: textFieldData.validationRegexp,
              onChanged: (newValue) {
                if (path != null) {
                  itemContext.dataContext.update(DataPath(path), newValue);
                }
              },
              onSubmitted: (newValue) {
                final JsonMap? actionData = textFieldData.onSubmittedAction;
                if (actionData == null) {
                  return;
                }
                final actionName = actionData['name'] as String;
                final List<Object?> contextDefinition =
                    (actionData['context'] as List<Object?>?) ?? <Object?>[];
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
              },
            );
          },
        );
      },
    );
  },
);
