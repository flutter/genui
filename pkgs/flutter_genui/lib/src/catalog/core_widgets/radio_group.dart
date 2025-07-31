// ignore_for_file: avoid_dynamic_calls

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';

final _schema = Schema.object(
  properties: {
    'groupValue': Schema.string(
      description: 'The currently selected value for a group of radio buttons.',
    ),
    'labels': Schema.array(
      items: Schema.string(),
      description: 'A list of labels for the radio buttons.',
    ),
  },
);

class _RadioGroup extends StatefulWidget {
  const _RadioGroup({
    required this.initialGroupValue,
    required this.labels,
    required this.onChanged,
  });

  final String initialGroupValue;
  final List<String> labels;
  final void Function(String?) onChanged;

  @override
  State<_RadioGroup> createState() => _RadioGroupState();
}

class _RadioGroupState extends State<_RadioGroup> {
  late String _groupValue;

  @override
  void initState() {
    super.initState();
    _groupValue = widget.initialGroupValue;
  }

  @override
  void didUpdateWidget(_RadioGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialGroupValue != oldWidget.initialGroupValue) {
      _groupValue = widget.initialGroupValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    void changedCallback(String? newValue) {
      if (newValue == null) return;
      setState(() {
        _groupValue = newValue;
      });
      widget.onChanged(newValue);
    }

    return Column(
      children: widget.labels.map((label) {
        return RadioListTile<String>(
          title: Text(label),
          value: label,
          // ignore: deprecated_member_use
          groupValue: _groupValue,
          // ignore: deprecated_member_use
          onChanged: changedCallback,
        );
      }).toList(),
    );
  }
}

final radioGroup = CatalogItem(
  name: 'radio_group',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final groupValue = data['groupValue'] as String;
        final labels = (data['labels'] as List<dynamic>).cast<String>();

        return _RadioGroup(
          initialGroupValue: groupValue,
          labels: labels,
          onChanged: (newValue) {
            if (newValue != null) {
              dispatchEvent(
                widgetId: id,
                eventType: 'onChanged',
                value: newValue,
              );
            }
          },
        );
      },
);
