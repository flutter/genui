// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'input_group.dart';
library;

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'common.dart';

final _schema = S.object(
  description:
      'A chip used to choose from a set of options where *more than one* '
      'option can be chosen. This *must* be placed inside an InputGroup.',
  properties: {
    'component': S.string(enumValues: ['CheckboxFilterChipsInput']),
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
    'selectedOptions': A2uiSchemas.stringArrayReference(
      description:
          'The names of the options that should be selected '
          'initially. These options must exist in the "options" list.',
    ),
  },
  required: ['component', 'chipLabel', 'options', 'selectedOptions'],
);

extension type _CheckboxFilterChipsInputData.fromMap(
  Map<String, Object?> _json
) {
  factory _CheckboxFilterChipsInputData({
    required String chipLabel,
    required List<String> options,
    String? iconName,
    required JsonMap selectedOptions,
  }) => _CheckboxFilterChipsInputData.fromMap({
    'chipLabel': chipLabel,
    'options': options,
    'iconName': ?iconName,
    'selectedOptions': selectedOptions,
  });

  String get chipLabel => _json['chipLabel'] as String;
  List<String> get options => (_json['options'] as List).cast<String>();
  String? get iconName => _json['iconName'] as String?;
  Object get selectedOptions => _json['selectedOptions'] as Object;
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
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "CheckboxFilterChipsInput",
          "chipLabel": "Amenities",
          "options": [
            "Wifi",
            "Gym",
            "Pool",
            "Parking"
          ],
          "selectedOptions": [
            "Wifi",
            "Gym"
          ]
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final checkboxFilterChipsData = _CheckboxFilterChipsInputData.fromMap(
      context.data as Map<String, Object?>,
    );
    IconData? icon;
    if (checkboxFilterChipsData.iconName != null) {
      try {
        icon = iconFor(
          TravelIcon.values.byName(checkboxFilterChipsData.iconName!),
        );
      } catch (e) {
        developer.log(
          'Invalid icon name: ${checkboxFilterChipsData.iconName}',
          name: 'CheckboxFilterChipsInput',
          error: e,
        );
        icon = null;
      }
    }

    final Object selectedOptionsRef = checkboxFilterChipsData.selectedOptions;
    final path =
        (selectedOptionsRef is Map && selectedOptionsRef.containsKey('path'))
        ? selectedOptionsRef['path'] as String
        : '${context.id}.value';

    return BoundList(
      dataContext: context.dataContext,
      value: {'path': path},
      builder: (buildContext, currentSelectedValues) {
        var effectiveSelections = currentSelectedValues;
        if (effectiveSelections == null) {
          if (selectedOptionsRef is List) {
            effectiveSelections = selectedOptionsRef;
          }
        }

        final Set<String> selectedOptionsSet = (effectiveSelections ?? [])
            .cast<String>()
            .toSet();
        return _CheckboxFilterChip(
          chipLabel: checkboxFilterChipsData.chipLabel,
          options: checkboxFilterChipsData.options,
          icon: icon,
          selectedOptions: selectedOptionsSet,
          onChanged: (newSelectedOptions) {
            context.dataContext.update(
              DataPath(path),
              newSelectedOptions.toList(),
            );
          },
        );
      },
    );
  },
);

class _CheckboxFilterChip extends StatelessWidget {
  const _CheckboxFilterChip({
    required this.chipLabel,
    required this.options,
    this.icon,
    required this.selectedOptions,
    required this.onChanged,
  });

  final String chipLabel;
  final List<String> options;
  final IconData? icon;
  final Set<String> selectedOptions;
  final void Function(Set<String>) onChanged;

  String get _displayLabel {
    if (selectedOptions.isEmpty) {
      return chipLabel;
    }
    return selectedOptions.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: icon != null ? Icon(icon) : null,
      label: Text(_displayLabel),
      selected: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onSelected: (bool selected) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            var tempSelectedOptions = Set<String>.from(selectedOptions);
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
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
                        onChanged(tempSelectedOptions);
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
