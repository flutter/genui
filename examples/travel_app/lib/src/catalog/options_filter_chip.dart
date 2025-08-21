// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'filter_chip_group.dart';
library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
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
    'iconChild': S.string(
      description:
          'An icon to display on the left of the chip. '
          'This should be an icon widget. Always use this if there is a '
          'relevant icon.',
    ),
  },
  required: ['chipLabel', 'options'],
);

extension type _OptionsFilterChipData.fromMap(Map<String, Object?> _json) {
  factory _OptionsFilterChipData({
    required String chipLabel,
    required List<String> options,
    String? iconChild,
  }) => _OptionsFilterChipData.fromMap({
    'chipLabel': chipLabel,
    'options': options,
    if (iconChild != null) 'iconChild': iconChild,
  });

  String get chipLabel => _json['chipLabel'] as String;
  List<String> get options => (_json['options'] as List).cast<String>();
  String? get iconChild => _json['iconChild'] as String?;
}

/// An interactive chip that allows the user to select a single option from a
/// predefined list.
///
/// This widget is a key component for gathering user preferences. It displays a
/// category (e.g., "Budget," "Activity Type") and, when tapped, presents a
/// modal bottom sheet containing a list of radio buttons for the available
/// options.
///
/// It is typically used within a [filterChipGroup] to manage multiple facets of
/// a user's query. When an option is selected, it dispatches a [UiChangeEvent],
/// which informs the AI of the user's choice, allowing it to refine its
/// subsequent responses.
final optionsFilterChip = CatalogItem(
  name: 'OptionsFilterChip',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final optionsFilterChipData = _OptionsFilterChipData.fromMap(
          data as Map<String, Object?>,
        );
        return _OptionsFilterChip(
          initialChipLabel: optionsFilterChipData.chipLabel,
          options: optionsFilterChipData.options,
          widgetId: id,
          dispatchEvent: dispatchEvent,
          iconChild: optionsFilterChipData.iconChild != null
              ? buildChild(optionsFilterChipData.iconChild!)
              : null,
        );
      },
);

class _OptionsFilterChip extends StatefulWidget {
  const _OptionsFilterChip({
    required this.initialChipLabel,
    required this.options,
    required this.widgetId,
    required this.dispatchEvent,
    this.iconChild,
  });

  final String initialChipLabel;
  final List<String> options;
  final String widgetId;
  final Widget? iconChild;
  final DispatchEventCallback dispatchEvent;

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
      avatar: widget.iconChild,
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
                            UiChangeEvent(
                              widgetId: widget.widgetId,
                              eventType: 'filterOptionSelected',
                              value: newValue,
                            ),
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
