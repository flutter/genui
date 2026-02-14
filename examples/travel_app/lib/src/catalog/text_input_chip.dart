// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  description:
      'An input chip used to ask the user to enter free text, e.g. to '
      'select a destination. This should only be used inside an InputGroup.',
  properties: {
    'component': S.string(enumValues: ['TextInputChip']),
    'label': S.string(description: 'The label for the text input chip.'),
    'value': A2uiSchemas.stringReference(
      description: 'The initial value for the text input.',
    ),
    'obscured': S.boolean(
      description: 'Whether the text should be obscured (e.g., for passwords).',
    ),
  },
  required: ['component', 'label'],
);

extension type _TextInputChipData.fromMap(Map<String, Object?> _json) {
  factory _TextInputChipData({
    required String label,
    JsonMap? value,
    bool? obscured,
  }) => _TextInputChipData.fromMap({
    'label': label,
    'value': ?value,
    'obscured': obscured ?? false,
  });

  String get label => _json['label'] as String;
  Object? get value => _json['value'];
  bool get obscured => _json['obscured'] as bool? ?? false;
}

final textInputChip = CatalogItem(
  name: 'TextInputChip',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "TextInputChip",
          "value": "John Doe",
          "label": "Enter your name"
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": "TextInputChip",
          "label": "Enter your password",
          "obscured": true
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final textInputChipData = _TextInputChipData.fromMap(
      context.data as Map<String, Object?>,
    );

    final Object? valueRef = textInputChipData.value;
    final path = valueRef is Map && valueRef.containsKey('path')
        ? valueRef['path'] as String
        : '${context.id}.value';
    final ValueNotifier<String?> notifier = context.dataContext
        .subscribeToString({'path': path});

    return ValueListenableBuilder<String?>(
      valueListenable: notifier,
      builder: (builderContext, currentValue, child) {
        final String? effectiveValue =
            currentValue ?? (valueRef is String ? valueRef : null);
        return _TextInputChip(
          label: textInputChipData.label,
          value: effectiveValue,
          obscured: textInputChipData.obscured,
          onChanged: (newValue) {
            context.dataContext.update(path, newValue);
          },
        );
      },
    );
  },
);

class _TextInputChip extends StatefulWidget {
  const _TextInputChip({
    required this.label,
    this.value,
    this.obscured = false,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final bool obscured;
  final void Function(String) onChanged;

  @override
  State<_TextInputChip> createState() => _TextInputChipState();
}

class _TextInputChipState extends State<_TextInputChip> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(_TextInputChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _textController.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        widget.obscured && (widget.value?.isNotEmpty ?? false)
            ? '********'
            : widget.value ?? widget.label,
      ),
      selected: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onSelected: (bool selected) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _textController,
                    obscureText: widget.obscured,
                    decoration: InputDecoration(labelText: widget.label),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      final String newValue = _textController.text;
                      if (newValue.isNotEmpty) {
                        widget.onChanged(newValue);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
