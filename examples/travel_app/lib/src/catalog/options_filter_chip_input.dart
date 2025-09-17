// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'input_group.dart';
library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'common.dart';

final _schema = S.object(
  description:
      'A chip used to choose from a set of mutually exclusive '
      'options. This *must* be placed inside an InputGroup.',
  properties: {
    'chipLabel': S.string(
      description:
          'The title of the filter chip e.g. "budget" or "activity type" '
          'etc',
    ),
    'options': S.list(
      description:
          '''The list of options that the user can choose from. There should be at least three of these.''',
      items: S.string(),
    ),
    'iconName': S.string(
      description: 'An icon to display on the left of the chip.',
      enumValues: TravelIcon.values.map((e) => e.name).toList(),
    ),
    'initialValue': S.string(
      description:
          'The name of the option that should be selected initially. This '
          'option must exist in the "options" list.',
    ),
  },
  required: ['chipLabel', 'options'],
);

extension type _OptionsFilterChipInputData.fromMap(Map<String, Object?> _json) {
  factory _OptionsFilterChipInputData({
    required String chipLabel,
    required List<String> options,
    String? iconName,
    String? initialValue,
  }) => _OptionsFilterChipInputData.fromMap({
    'chipLabel': chipLabel,
    'options': options,
    if (iconName != null) 'iconName': iconName,
    if (initialValue != null) 'initialValue': initialValue,
  });

  String get chipLabel => _json['chipLabel'] as String;
  List<String> get options => (_json['options'] as List).cast<String>();
  String? get iconName => _json['iconName'] as String?;
  String? get initialValue => _json['initialValue'] as String?;
}

/// An interactive chip that allows the user to select a single option from a
/// predefined list.
///
/// This widget is a key component for gathering user preferences. It displays a
/// category (e.g., "Budget," "Activity Type") and, when tapped, presents a
/// modal bottom sheet containing a list of radio buttons for the available
/// options.
///
/// It is typically used within a [inputGroup] to manage multiple facets of
/// a user's query.
final optionsFilterChipInput = CatalogItem(
  name: 'OptionsFilterChipInput',
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
        final optionsFilterChipData = _OptionsFilterChipInputData.fromMap(
          data as Map<String, Object?>,
        );
        IconData? icon;
        if (optionsFilterChipData.iconName != null) {
          try {
            icon = iconFor(
              TravelIcon.values.byName(optionsFilterChipData.iconName!),
            );
          } catch (e) {
            // Invalid icon name, default to no icon.
            // Consider logging this error.
            icon = null;
          }
        }
        return _OptionsFilterChip(
          initialChipLabel: optionsFilterChipData.chipLabel,
          options: optionsFilterChipData.options,
          widgetId: id,
          dispatchEvent: dispatchEvent,
          icon: icon,
          initialValue: optionsFilterChipData.initialValue,
          values: values,
        );
      },
);

class _OptionsFilterChip extends StatefulWidget {
  const _OptionsFilterChip({
    required this.initialChipLabel,
    required this.options,
    required this.widgetId,
    required this.dispatchEvent,
    required this.values,
    this.icon,
    this.initialValue,
  });

  final String initialChipLabel;
  final List<String> options;
  final String widgetId;
  final IconData? icon;
  final DispatchEventCallback dispatchEvent;
  final String? initialValue;
  final Map<String, Object?> values;

  @override
  State<_OptionsFilterChip> createState() => _OptionsFilterChipState();
}

class _OptionsFilterChipState extends State<_OptionsFilterChip> {
  late String _currentChipLabel;

  @override
  void initState() {
    super.initState();
    _currentChipLabel = widget.initialValue ?? widget.initialChipLabel;
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: widget.icon != null ? Icon(widget.icon) : null,
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
                        widget.values[widget.widgetId] = newValue;
                        if (newValue != null) {
                          setState(() {
                            _currentChipLabel = newValue;
                          });
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
