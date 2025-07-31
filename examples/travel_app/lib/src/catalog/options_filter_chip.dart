import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  properties: {
    'label': Schema.string(description: 'The label for the filter category.'),
    'options': Schema.array(
      description: 'The list of options to display as filter chips.',
      items: Schema.string(),
    ),
  },
);

final optionsFilterChip = CatalogItem(
  name: 'optionsFilterChip',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
  }) {
    final label = data['label'] as String?;
    final options = (data['options'] as List).cast<String>();
    return _OptionsFilterChip(
      widgetId: id,
      label: label,
      options: options,
      dispatchEvent: dispatchEvent,
    );
  },
);

class _OptionsFilterChip extends StatefulWidget {
  const _OptionsFilterChip({
    required this.widgetId,
    this.label,
    required this.options,
    required this.dispatchEvent,
  });

  final String widgetId;
  final String? label;
  final List<String> options;
  final void Function(
      {required String widgetId,
      required String eventType,
      required Object? value}) dispatchEvent;

  @override
  State<_OptionsFilterChip> createState() => _OptionsFilterChipState();
}

class _OptionsFilterChipState extends State<_OptionsFilterChip> {
  final Set<String> _selectedOptions = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(widget.label!, style: Theme.of(context).textTheme.titleMedium),
        if (widget.label != null) const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.options.map((option) {
            final isSelected = _selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedOptions.add(option);
                  } else {
                    _selectedOptions.remove(option);
                  }
                });
                widget.dispatchEvent(
                  widgetId: widget.widgetId,
                  eventType: 'selectionChanged',
                  value: _selectedOptions.toList(),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
