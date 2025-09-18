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
      'A chip used to choose from a set of options where *more than one* '
      'option can be chosen. This *must* be placed inside an InputGroup.',
  properties: {
    'chipLabel': S.string(
      description:
          'The title of the filter chip e.g. "amenities" or "dietary '
          'restrictions" etc',
    ),
    'options': S.list(
      description: '''The list of options that the user can choose from.''',
      items: S.string(),
    ),
    'iconName': S.string(
      description: 'An icon to display on the left of the chip.',
      enumValues: TravelIcon.values.map((e) => e.name).toList(),
    ),
    'initialOptions': S.list(
      description:
          'The names of the options that should be selected '
          'initially. These options must exist in the "options" list.',
      items: S.string(description: 'An option from the "options" list.'),
    ),
  },
  required: ['chipLabel', 'options'],
);

extension type _CheckboxFilterChipsInputData.fromMap(
  Map<String, Object?> _json
) {
  factory _CheckboxFilterChipsInputData({
    required String chipLabel,
    required List<String> options,
    String? iconName,
    List<String>? initialOptions,
  }) => _CheckboxFilterChipsInputData.fromMap({
    'chipLabel': chipLabel,
    'options': options,
    if (iconName != null) 'iconName': iconName,
    if (initialOptions != null) 'initialOptions': initialOptions,
  });

  String get chipLabel => _json['chipLabel'] as String;
  List<String> get options => (_json['options'] as List).cast<String>();
  String? get iconName => _json['iconName'] as String?;
  List<String> get initialOptions =>
      (_json['initialOptions'] as List?)?.cast<String>() ?? [];
}

/// An interactive chip that allows the user to select multiple options from a
/// predefined list.
///
/// This widget is a key component for gathering user preferences. It displays a
/// category (e.g., "Amenities," "Dietary Restrictions") and, when tapped,
/// presents a
/// modal bottom sheet containing a list of checkboxes for the available
/// options.
///
/// It is typically used within a [inputGroup] to manage multiple facets of
/// a user's query.
final checkboxFilterChipsInput = CatalogItem(
  name: 'CheckboxFilterChipsInput',
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
        final checkboxFilterChipsData = _CheckboxFilterChipsInputData.fromMap(
          data as Map<String, Object?>,
        );
        IconData? icon;
        if (checkboxFilterChipsData.iconName != null) {
          try {
            icon = iconFor(
              TravelIcon.values.byName(checkboxFilterChipsData.iconName!),
            );
          } catch (e) {
            // Invalid icon name, default to no icon.
            // Consider logging this error.
            icon = null;
          }
        }
        return _CheckboxFilterChip(
          initialChipLabel: checkboxFilterChipsData.chipLabel,
          options: checkboxFilterChipsData.options,
          widgetId: id,
          dispatchEvent: dispatchEvent,
          icon: icon,
          initialOptions: checkboxFilterChipsData.initialOptions,
          values: values,
        );
      },
);

class _CheckboxFilterChip extends StatefulWidget {
  const _CheckboxFilterChip({
    required this.initialChipLabel,
    required this.options,
    required this.widgetId,
    required this.dispatchEvent,
    required this.values,
    this.icon,
    this.initialOptions,
  });

  final String initialChipLabel;
  final List<String> options;
  final String widgetId;
  final IconData? icon;
  final DispatchEventCallback dispatchEvent;
  final List<String>? initialOptions;
  final Map<String, Object?> values;

  @override
  State<_CheckboxFilterChip> createState() => _CheckboxFilterChipState();
}

class _CheckboxFilterChipState extends State<_CheckboxFilterChip> {
  late List<String> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptions = widget.initialOptions ?? [];
  }

  String get _chipLabel {
    if (_selectedOptions.isEmpty) {
      return widget.initialChipLabel;
    }
    return _selectedOptions.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: widget.icon != null ? Icon(widget.icon) : null,
      label: Text(_chipLabel),
      selected: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onSelected: (bool selected) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            var tempSelectedOptions = List<String>.from(_selectedOptions);
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.options.map((option) {
                    return CheckboxListTile(
                      title: Text(option),
                      value: tempSelectedOptions.contains(option),
                      onChanged: (bool? newValue) {
                        setModalState(() {
                          if (newValue == true) {
                            tempSelectedOptions.add(option);
                          } else {
                            tempSelectedOptions.remove(option);
                          }
                        });
                        setState(() {
                          _selectedOptions = List.from(tempSelectedOptions);
                        });
                        widget.values[widget.widgetId] = tempSelectedOptions;
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
