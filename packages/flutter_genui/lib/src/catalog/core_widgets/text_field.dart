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
    'value': A2uiSchemas.stringReference(
      description: 'The initial value of the text field.',
    ),
    'hintText': S.string(description: 'Hint text for the text field.'),
    'obscureText': S.boolean(
      description: 'Whether the text should be obscured.',
    ),
    'onSubmittedAction': A2uiSchemas.action(
      description: 'The action to perform when the text field is submitted.',
    ),
  },
);

extension type _TextFieldData.fromMap(JsonMap _json) {
  factory _TextFieldData({
    required JsonMap value,
    String? hintText,
    bool? obscureText,
    JsonMap? onSubmittedAction,
  }) => _TextFieldData.fromMap({
    'value': value,
    'hintText': hintText,
    'obscureText': obscureText,
    'onSubmittedAction': onSubmittedAction,
  });

  JsonMap get value => _json['value'] as JsonMap;
  String? get hintText => _json['hintText'] as String?;
  bool get obscureText => (_json['obscureText'] as bool?) ?? false;
  JsonMap? get onSubmittedAction => _json['onSubmittedAction'] as JsonMap?;
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.initialValue,
    this.hintText,
    this.obscureText = false,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String initialValue;
  final String? hintText;
  final bool obscureText;
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
      decoration: InputDecoration(hintText: widget.hintText),
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}

final textField = CatalogItem(
  name: 'TextField',
  dataSchema: _schema,
  exampleData: [
    () => {
      'root': 'text_field',
      'widgets': [
        {
          'id': 'text_field',
          'widget': {
            'TextField': {
              'value': {'literalString': 'Hello World'},
            },
          },
        },
      ],
    },
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
        final valueRef = textFieldData.value;
        final path = valueRef['path'] as String?;
        final notifier = dataContext.subscribeToString(valueRef);

        return ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, currentValue, child) {
            return _TextField(
              initialValue: currentValue ?? '',
              hintText: textFieldData.hintText,
              obscureText: textFieldData.obscureText,
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
                final actionName = actionData['actionName'] as String;
                final contextDefinition =
                    (actionData['context'] as List<Object?>?) ?? <Object?>[];
                final resolvedContext = resolveContext(
                  dataContext,
                  contextDefinition,
                );
                dispatchEvent(
                  UserActionEvent(
                    actionName: actionName,
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
