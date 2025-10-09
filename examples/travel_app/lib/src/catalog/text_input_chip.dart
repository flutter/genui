// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  description:
      'An input chip used to ask the user to enter free text, e.g. to '
      'select a destination. This should only be used inside an InputGroup.',
  properties: {
    'label': S.string(description: 'The label for the text input chip.'),
    'value': A2uiSchemas.stringReference(
      description: 'The initial value for the text input.',
    ),
  },
  required: ['label'],
);

extension type _TextInputChipData.fromMap(Map<String, Object?> _json) {
  factory _TextInputChipData({required String label, JsonMap? value}) =>
      _TextInputChipData.fromMap({
        'label': label,
        if (value != null) 'value': value,
      });

  String get label => _json['label'] as String;
  JsonMap? get value => _json['value'] as JsonMap?;
}

final textInputChip = CatalogItem(
  name: 'TextInputChip',
  dataSchema: _schema,
  exampleData: [
    () => {
      'root': 'text_input',
      'widgets': [
        {
          'id': 'text_input',
          'widget': {
            'TextInputChip': {
              'value': {'literalString': 'John Doe'},
              'label': 'Enter your name',
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
        final textInputChipData = _TextInputChipData.fromMap(
          data as Map<String, Object?>,
        );

        final valueRef = textInputChipData.value;
        final path = valueRef?['path'] as String?;
        final notifier = dataContext.subscribeToString(valueRef);

        return ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, currentValue, child) {
            return _TextInputChip(
              label: textInputChipData.label,
              value: currentValue,
              onChanged: (newValue) {
                if (path != null) {
                  dataContext.update(path, newValue);
                }
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
    required this.onChanged,
  });

  final String label;
  final String? value;
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
      label: Text(widget.value ?? widget.label),
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
                    decoration: InputDecoration(labelText: widget.label),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      final newValue = _textController.text;
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
