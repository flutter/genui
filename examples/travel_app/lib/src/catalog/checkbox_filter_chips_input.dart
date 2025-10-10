// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'input_group.dart';
library;

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

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
    'selectedOptions': A2uiSchemas.stringArrayReference(
      description:
          'The names of the options that should be selected '
          'initially. These options must exist in the "options" list.',
    ),
  },
  required: ['chipLabel', 'options', 'selectedOptions'],
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
    if (iconName != null) 'iconName': iconName,
    'selectedOptions': selectedOptions,
  });

  String get chipLabel => _json['chipLabel'] as String;
  List<String> get options => (_json['options'] as List).cast<String>();
  String? get iconName => _json['iconName'] as String?;
  JsonMap get selectedOptions => _json['selectedOptions'] as JsonMap;
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
        required dataContext,
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
            developer.log(
              'Invalid icon name: ${checkboxFilterChipsData.iconName}',
              name: 'CheckboxFilterChipsInput',
              error: e,
            );
            icon = null;
          }
        }

        final selectedOptionsRef = checkboxFilterChipsData.selectedOptions;
        final notifier = dataContext.subscribeToStringArray(selectedOptionsRef);

        return ValueListenableBuilder<List<dynamic>?>(
          valueListenable: notifier,
          builder: (context, currentSelectedValues, child) {
            final selectedOptionsSet = (currentSelectedValues ?? [])
                .cast<String>()
                .toSet();
            return _CheckboxFilterChip(
              chipLabel: checkboxFilterChipsData.chipLabel,
              options: checkboxFilterChipsData.options,
              icon: icon,
              selectedOptions: selectedOptionsSet,
              onChanged: (newSelectedOptions) {
                final path = selectedOptionsRef['path'] as String?;
                if (path != null) {
                  dataContext.update(path, newSelectedOptions.toList());
                }
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
