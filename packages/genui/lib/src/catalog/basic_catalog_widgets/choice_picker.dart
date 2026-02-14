// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../primitives/simple_items.dart';
import '../../widgets/widget_utilities.dart';
import 'widget_helpers.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['ChoicePicker']),
    'label': A2uiSchemas.stringReference(
      description: 'The label for the group of options.',
    ),
    'options': A2uiSchemas.listOrReference(
      description: 'The list of available options to choose from.',
      items: S.object(
        properties: {
          'label': A2uiSchemas.stringReference(
            description: 'The text to display for this option.',
          ),
          'value': S.string(
            description: 'The stable value associated with this option.',
          ),
        },
        required: ['label', 'value'],
      ),
    ),
    'value': S.combined(
      oneOf: [
        S.string(),
        S.list(items: S.string()),
        A2uiSchemas.dataBindingSchema(),
        A2uiSchemas.functionCall(),
      ],
      description: 'The list of currently selected values (or single value).',
    ),
    'displayStyle': S.string(
      description: 'The display style of the component.',
      enumValues: ['checkbox', 'chips'],
    ),
    'variant': S.string(
      description:
          'A hint for how the choice picker should be displayed and behave.',
      enumValues: ['multipleSelection', 'mutuallyExclusive'],
    ),
    'filterable': S.boolean(
      description: 'Whether the options can be filtered by the user.',
    ),
    'checks': A2uiSchemas.checkable(),
  },
  required: ['component', 'options', 'value'],
);

extension type _ChoicePickerData.fromMap(JsonMap _json) {
  Object? get label => _json['label'];
  String? get variant => _json['variant'] as String?;
  Object? get options => _json['options'];
  Object get value => _json['value'] as Object;
  String? get displayStyle => _json['displayStyle'] as String?;
  bool get filterable => _json['filterable'] as bool? ?? false;
  List<JsonMap>? get checks => (_json['checks'] as List?)?.cast<JsonMap>();
}

/// A component that allows selecting one or more options from a list.
final choicePicker = CatalogItem(
  name: 'ChoicePicker',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final data = _ChoicePickerData.fromMap(itemContext.data as JsonMap);

    final Object valueRef = data.value;
    final path = (valueRef is Map && valueRef.containsKey('path'))
        ? valueRef['path'] as String
        : '${itemContext.id}.value';

    itemContext.dataContext.subscribe<Object>(path);

    final isMutuallyExclusive = data.variant == 'mutuallyExclusive';
    final isChips = data.displayStyle == 'chips';

    final Object? optionsRef = data.options;
    final ValueNotifier<List<Object?>?> optionsNotifier;
    if (optionsRef is Map && optionsRef.containsKey('path')) {
      optionsNotifier = itemContext.dataContext.subscribe<List<Object?>>(
        optionsRef['path'] as String,
      );
    } else {
      optionsNotifier = ValueNotifier(optionsRef as List<Object?>?);
    }

    // Wrap the picker in validation
    return ValueListenableBuilder<Object?>(
      valueListenable: itemContext.dataContext.createComputedNotifier(
        checksToExpression(data.checks),
      ),
      builder: (context, isValid, _) {
        final isError = isValid == false;

        final Widget pickerWidget = _ChoicePicker(
          label: data.label,
          optionsNotifier: optionsNotifier,
          valueRef: valueRef,
          path: path,
          itemContext: itemContext,
          isMutuallyExclusive: isMutuallyExclusive,
          isChips: isChips,
          filterable: data.filterable,
        );

        if (!isError) {
          return pickerWidget;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pickerWidget,
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Text(
                'Invalid selection',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "Column",
          "children": ["heading1", "radio", "heading2", "check"]
        },
        { "id": "heading1", "component": "Text", "text": "Mutually Exclusive", "variant": "h4" },
        { "id": "radio", "component": "ChoicePicker", "variant": "mutuallyExclusive", "label": "Choose one", "value": ["A"], "options": [ { "label": "A", "value": "A" }, { "label": "B", "value": "B" } ] },
        { "id": "heading2", "component": "Text", "text": "Multiple Selection", "variant": "h4" },
        { "id": "check", "component": "ChoicePicker", "variant": "multipleSelection", "label": "Choose many", "value": { "path": "/multi" }, "options": [ { "label": "X", "value": "X" }, { "label": "Y", "value": "Y" } ] }
      ]
    ''',
  ],
  isImplicitlyFlexible: true,
);

class _ChoicePicker extends StatefulWidget {
  const _ChoicePicker({
    required this.label,
    required this.optionsNotifier,
    required this.valueRef,
    required this.path,
    required this.itemContext,
    required this.isMutuallyExclusive,
    required this.isChips,
    required this.filterable,
  });

  final Object? label;
  final ValueNotifier<List<Object?>?> optionsNotifier;
  final Object valueRef;
  final String path;
  final CatalogItemContext itemContext;
  final bool isMutuallyExclusive;
  final bool isChips;
  final bool filterable;

  @override
  State<_ChoicePicker> createState() => _ChoicePickerState();
}

class _ChoicePickerState extends State<_ChoicePicker> {
  String _filter = '';
  late final ValueNotifier<Object?> _selectionsNotifier;

  @override
  void initState() {
    super.initState();
    _selectionsNotifier = widget.itemContext.dataContext.subscribe<Object>(
      widget.path,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtering is handled in the build method of the options.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
            child: ValueListenableBuilder<String?>(
              valueListenable: widget.itemContext.dataContext.subscribeToString(
                widget.label!,
              ),
              builder: (context, label, child) {
                if (label == null || label.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
          ),
        if (widget.filterable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filter options',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value;
                });
              },
            ),
          ),
        ValueListenableBuilder<Object?>(
          valueListenable: _selectionsNotifier,
          builder: (context, currentSelections, child) {
            var effectiveSelections = currentSelections;
            if (effectiveSelections == null) {
              if (widget.valueRef is List) {
                effectiveSelections = widget.valueRef;
              } else if (widget.valueRef is String) {
                effectiveSelections = [widget.valueRef];
              }
            } else if (effectiveSelections is! List) {
              effectiveSelections = [effectiveSelections];
            }
            final List<String> currentStrings =
                (effectiveSelections as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];

            return ValueListenableBuilder<List<Object?>?>(
              valueListenable: widget.optionsNotifier,
              builder: (context, options, child) {
                if (options == null) {
                  return const SizedBox.shrink();
                }
                final List<JsonMap> castOptions = options.cast<JsonMap>();
                final List<Widget> optionWidgets = [];

                for (final option in castOptions) {
                  final ValueNotifier<String?> labelNotifier = widget
                      .itemContext
                      .dataContext
                      .subscribeToString(option['label']);
                  final optionValue = option['value'] as String;

                  optionWidgets.add(
                    ValueListenableBuilder<String?>(
                      valueListenable: labelNotifier,
                      builder: (context, label, child) {
                        if (widget.filterable &&
                            _filter.isNotEmpty &&
                            label != null &&
                            !label.toLowerCase().contains(
                              _filter.toLowerCase(),
                            )) {
                          return const SizedBox.shrink();
                        }

                        if (widget.isChips) {
                          final bool selected = currentStrings.contains(
                            optionValue,
                          );
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: FilterChip(
                              label: Text(label ?? ''),
                              selected: selected,
                              onSelected: (bool selected) {
                                _updateSelection(
                                  selected,
                                  optionValue,
                                  currentStrings,
                                );
                              },
                            ),
                          );
                        }

                        if (widget.isMutuallyExclusive) {
                          final Object? groupValue = currentStrings.isNotEmpty
                              ? currentStrings.first
                              : null;

                          return RadioListTile<String>(
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            title: Text(label ?? ''),
                            value: optionValue,
                            // ignore: deprecated_member_use
                            groupValue: groupValue is String
                                ? groupValue
                                : null,
                            // ignore: deprecated_member_use
                            onChanged: (newValue) {
                              if (newValue == null) return;
                              widget.itemContext.dataContext.update(
                                widget.path,
                                [newValue],
                              );
                            },
                          );
                        } else {
                          return CheckboxListTile(
                            title: Text(label ?? ''),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: currentStrings.contains(optionValue),
                            onChanged: (newValue) {
                              _updateSelection(
                                newValue == true,
                                optionValue,
                                currentStrings,
                              );
                            },
                          );
                        }
                      },
                    ),
                  );
                }

                if (widget.isChips) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(children: optionWidgets),
                  );
                }

                return Column(children: optionWidgets);
              },
            );
          },
        ),
      ],
    );
  }

  void _updateSelection(
    bool selected,
    String optionValue,
    List<String> currentStrings,
  ) {
    if (widget.isMutuallyExclusive) {
      if (selected) {
        widget.itemContext.dataContext.update(widget.path, [optionValue]);
      }
    } else {
      final newSelections = List<String>.from(currentStrings);
      if (selected) {
        if (!newSelections.contains(optionValue)) {
          newSelections.add(optionValue);
        }
      } else {
        newSelections.remove(optionValue);
      }
      widget.itemContext.dataContext.update(widget.path, newSelections);
    }
  }
}
