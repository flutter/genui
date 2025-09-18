// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  description:
      'An input chip used to ask the user to enter free text, e.g. to '
      'select a destination. This should only be used inside an InputGroup.',
  properties: {
    'label': S.string(description: 'The label for the text input chip.'),
    'initialValue': S.string(
      description: 'The initial value for the text input.',
    ),
  },
  required: ['label'],
);

extension type _TextInputChipData.fromMap(Map<String, Object?> _json) {
  factory _TextInputChipData({required String label, String? initialValue}) =>
      _TextInputChipData.fromMap({
        'label': label,
        if (initialValue != null) 'initialValue': initialValue,
      });

  String get label => _json['label'] as String;
  String? get initialValue => _json['initialValue'] as String?;
}

final textInputChip = CatalogItem(
  name: 'TextInputChip',
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
        final textInputChipData = _TextInputChipData.fromMap(
          data as Map<String, Object?>,
        );
        return _TextInputChip(
          label: textInputChipData.label,
          initialValue: textInputChipData.initialValue,
          widgetId: id,
          dispatchEvent: dispatchEvent,
          values: values,
        );
      },
);

class _TextInputChip extends StatefulWidget {
  const _TextInputChip({
    required this.label,
    this.initialValue,
    required this.widgetId,
    required this.dispatchEvent,
    required this.values,
  });

  final String label;
  final String? initialValue;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;
  final Map<String, Object?> values;

  @override
  State<_TextInputChip> createState() => _TextInputChipState();
}

class _TextInputChipState extends State<_TextInputChip> {
  late String _currentValue;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue ?? widget.label;
    _textController.text = widget.initialValue ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(_currentValue),
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
                        widget.values[widget.widgetId] = newValue;
                        setState(() {
                          _currentValue = newValue;
                        });
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
