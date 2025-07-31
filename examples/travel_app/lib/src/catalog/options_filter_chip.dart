import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  properties: {
    'chipLabel': Schema.string(
      description:
          'The title of the filter chip e.g. "budget" or "activity type" etc',
    ),
    'options': Schema.array(
      description:
          '''The list of options that the user can choose from. There should be at least three of these.''',
      items: Schema.string(),
    ),
  },
);

final optionsFilterChip = CatalogItem(
  name: 'optionsFilterChip',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final chipLabel = (data as Map)['chipLabel'] as String;
        final options = (data['options'] as List<dynamic>).cast<String>();

        return _OptionsFilterChip(
          initialChipLabel: chipLabel,
          options: options,
          widgetId: id,
          dispatchEvent: dispatchEvent,
        );
      },
);

class _OptionsFilterChip extends StatefulWidget {
  const _OptionsFilterChip({
    required this.initialChipLabel,
    required this.options,
    required this.widgetId,
    required this.dispatchEvent,
  });

  final String initialChipLabel;
  final List<String> options;
  final String widgetId;
  final void Function({
    required String widgetId,
    required String eventType,
    required Object? value,
  })
  dispatchEvent;

  @override
  State<_OptionsFilterChip> createState() => _OptionsFilterChipState();
}

class _OptionsFilterChipState extends State<_OptionsFilterChip> {
  late String _currentChipLabel;

  @override
  void initState() {
    super.initState();
    _currentChipLabel = widget.initialChipLabel;
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(_currentChipLabel),
      selected: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onSelected: (bool selected) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            String? tempSelectedOption = _currentChipLabel;
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.options.map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      // ignore: deprecated_member_use
                      groupValue: tempSelectedOption,
                      // ignore: deprecated_member_use
                      onChanged: (String? newValue) {
                        setModalState(() {
                          tempSelectedOption = newValue;
                        });
                        if (newValue != null) {
                          setState(() {
                            _currentChipLabel = newValue;
                          });
                          widget.dispatchEvent(
                            widgetId: widget.widgetId,
                            eventType: 'optionSelected',
                            value: newValue,
                          );
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            );
          },
        );
      },
    );
  }
}
