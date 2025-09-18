// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';
import '../../model/ui_models.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'value': S.string(description: 'The initial value of the text field.'),
    'hintText': S.string(description: 'Hint text for the text field.'),
    'obscureText': S.boolean(
      description: 'Whether the text should be obscured.',
    ),
  },
);

extension type _TextFieldData.fromMap(JsonMap _json) {
  factory _TextFieldData({
    String? value,
    String? hintText,
    bool? obscureText,
  }) => _TextFieldData.fromMap({
    'value': value,
    'hintText': hintText,
    'obscureText': obscureText,
  });

  String get value => (_json['value'] as String?) ?? '';
  String? get hintText => _json['hintText'] as String?;
  bool get obscureText => (_json['obscureText'] as bool?) ?? false;
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
    if (widget.initialValue != oldWidget.initialValue) {
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
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final textFieldData = _TextFieldData.fromMap(data as JsonMap);
        return _TextField(
          initialValue: textFieldData.value,
          hintText: textFieldData.hintText,
          obscureText: textFieldData.obscureText,
          onChanged: (newValue) => values[id] = newValue,
          onSubmitted: (newValue) {
            dispatchEvent(
              UiActionEvent(
                widgetId: id,
                eventType: 'onSubmitted',
                value: newValue,
              ),
            );
          },
        );
      },
);
