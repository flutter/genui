// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'input_group.dart';
library;

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

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
    'value': A2uiSchemas.stringReference(
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
    JsonMap? value,
  }) => _OptionsFilterChipInputData.fromMap({
    'chipLabel': chipLabel,
    'options': options,
    if (iconName != null) 'iconName': iconName,
    if (value != null) 'value': value,
  });

  String get chipLabel => _json['chipLabel'] as String;
  List<String> get options => (_json['options'] as List).cast<String>();
  String? get iconName => _json['iconName'] as String?;
  JsonMap? get value => _json['value'] as JsonMap?;
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
        required dataContext,
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
            icon = null;
          }
        }

        final valueRef = optionsFilterChipData.value;
        final path = valueRef?['path'] as String?;
        final notifier = dataContext.subscribeToString(valueRef);

        return ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, currentValue, child) {
            return _OptionsFilterChip(
              chipLabel: optionsFilterChipData.chipLabel,
              options: optionsFilterChipData.options,
              icon: icon,
              value: currentValue,
              onChanged: (newValue) {
                if (path != null && newValue != null) {
                  dataContext.update(path, newValue);
                }
              },
            );
          },
        );
      },
);

class _OptionsFilterChip extends StatelessWidget {
  const _OptionsFilterChip({
    required this.chipLabel,
    required this.options,
    this.icon,
    this.value,
    required this.onChanged,
  });

  final String chipLabel;
  final List<String> options;
  final IconData? icon;
  final String? value;
  final void Function(String?) onChanged;

  String get _currentChipLabel => value ?? chipLabel;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: icon != null ? Icon(icon) : null,
      label: Text(_currentChipLabel),
      selected: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onSelected: (bool selected) {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            var tempSelectedOption = value;
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
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
                        onChanged(newValue);
                        if (newValue != null) {
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
