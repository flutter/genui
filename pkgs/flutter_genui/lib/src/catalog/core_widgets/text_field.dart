// ignore_for_file: avoid_dynamic_calls

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';

final _schema = Schema.object(
  properties: {
    'value': Schema.string(description: 'The initial value of the text field.'),
    'hintText': Schema.string(description: 'Hint text for the text field.'),
    'obscureText': Schema.boolean(
      description: 'Whether the text should be obscured.',
    ),
  },
);

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
  name: 'text_field',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
  }) {
    final value = data['value'] as String? ?? '';
    final hintText = data['hintText'] as String?;
    final obscureText = data['obscureText'] as bool? ?? false;

    return _TextField(
      initialValue: value,
      hintText: hintText,
      obscureText: obscureText,
      onChanged: (newValue) {
        dispatchEvent(widgetId: id, eventType: 'onChanged', value: newValue);
      },
      onSubmitted: (newValue) {
        dispatchEvent(widgetId: id, eventType: 'onSubmitted', value: newValue);
      },
    );
  },
);
