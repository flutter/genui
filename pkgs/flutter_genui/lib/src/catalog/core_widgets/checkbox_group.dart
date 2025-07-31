import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';

final _schema = Schema.object(
  properties: {
    'values': Schema.array(
      items: Schema.boolean(),
      description: 'The values of the checkboxes.',
    ),
    'labels': Schema.array(
      items: Schema.string(),
      description: 'A list of labels for the checkboxes.',
    ),
  },
);

extension type _CheckboxGroupData.fromMap(Map<String, Object?> _json) {
  factory _CheckboxGroupData({
    required List<bool> values,
    required List<String> labels,
  }) => _CheckboxGroupData.fromMap({'values': values, 'labels': labels});

  List<bool> get values => (_json['values'] as List).cast<bool>();
  List<String> get labels => (_json['labels'] as List).cast<String>();
}

class _CheckboxGroup extends StatefulWidget {
  const _CheckboxGroup({
    required this.initialValues,
    required this.labels,
    required this.onChanged,
  });

  final List<bool> initialValues;
  final List<String> labels;
  final void Function(List<bool>) onChanged;

  @override
  State<_CheckboxGroup> createState() => _CheckboxGroupState();
}

class _CheckboxGroupState extends State<_CheckboxGroup> {
  late List<bool> _values;

  @override
  void initState() {
    super.initState();
    _values = List.from(widget.initialValues);
  }

  @override
  void didUpdateWidget(_CheckboxGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValues != oldWidget.initialValues) {
      _values = List.from(widget.initialValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < widget.labels.length; i++)
          CheckboxListTile(
            title: Text(widget.labels[i]),
            value: _values[i],
            onChanged: (bool? newValue) {
              if (newValue == null) return;
              setState(() {
                _values[i] = newValue;
              });
              widget.onChanged(_values);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }
}

final checkboxGroup = CatalogItem(
  name: 'checkbox_group',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final checkboxData = _CheckboxGroupData.fromMap(
          data as Map<String, Object?>,
        );
        return _CheckboxGroup(
          initialValues: checkboxData.values,
          labels: checkboxData.labels,
          onChanged: (newValues) {
            dispatchEvent(
              widgetId: id,
              eventType: 'onChanged',
              value: newValues,
            );
          },
        );
      },
);
