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

Widget _builder(
  dynamic data, // The actual deserialized JSON data for this layout
  String id,
  Widget Function(String id) buildChild,
  void Function(String widgetId, String eventType, Object? value) dispatchEvent,
  BuildContext context,
) {
  // ignore: avoid_dynamic_calls
  final values = (data['values'] as List<dynamic>).cast<bool>();
  // ignore: avoid_dynamic_calls
  final labels = (data['labels'] as List<dynamic>).cast<String>();

  return _CheckboxGroup(
    initialValues: values,
    labels: labels,
    onChanged: (newValues) {
      dispatchEvent(id, 'onChanged', newValues);
    },
  );
}

final checkboxGroup = CatalogItem(
  name: 'checkbox_group',
  dataSchema: _schema,
  widgetBuilder: _builder,
);
