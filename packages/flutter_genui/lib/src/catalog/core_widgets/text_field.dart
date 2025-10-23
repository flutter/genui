// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/ui_models.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
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
    required JsonMap text,
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

  JsonMap get text => _json['text'] as JsonMap;
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
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required dataContext,
      }) {
        final textFieldData = _TextFieldData.fromMap(data as JsonMap);
        final valueRef = textFieldData.text;
        final path = valueRef['path'] as String?;
        final notifier = dataContext.subscribeToString(valueRef);
        final labelNotifier = dataContext.subscribeToString(
          textFieldData.label,
        );

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
                      dataContext.update(path, newValue);
                    }
                  },
                  onSubmitted: (newValue) {
                    final actionData = textFieldData.onSubmittedAction;
                    if (actionData == null) {
                      return;
                    }
                    final actionName = actionData['name'] as String;
                    final contextDefinition =
                        (actionData['context'] as List<Object?>?) ??
                        <Object?>[];
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
                );
              },
            );
          },
        );
      },
);
