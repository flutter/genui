// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/widget_utilities.dart';
import '../../functions/expression_parser.dart';
import '../../model/a2ui_schemas.dart';
import '../../model/catalog_item.dart';
import '../../model/data_model.dart';
import '../../primitives/simple_items.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['DateTimeInput']),
    'value': A2uiSchemas.stringReference(
      description: 'The selected date and/or time.',
    ),
    'variant': S.string(
      description: 'The input type: date, time, or datetime.',
      enumValues: ['date', 'time', 'datetime'],
    ),
    'min': S.string(
      description:
          'The earliest selectable date (YYYY-MM-DD). Defaults to -9999-01-01.',
    ),
    'max': S.string(
      description:
          'The latest selectable date (YYYY-MM-DD). Defaults to 9999-12-31.',
    ),
    'label': A2uiSchemas.stringReference(
      description: 'The text label for the input field.',
    ),
    'checks': S.list(items: A2uiSchemas.validationCheck()),
  },
  required: ['component', 'value'],
);

extension type _DateTimeInputData.fromMap(JsonMap _json) {
  factory _DateTimeInputData({
    required JsonMap value,
    String? variant,
    String? min,
    String? max,
    Object? label,
    List<JsonMap>? checks,
  }) => _DateTimeInputData.fromMap({
    'value': value,
    'variant': variant,
    'min': min,
    'max': max,
    'label': label,
    'checks': checks,
  });

  Object get value => _json['value'] as Object;
  String? get variant => _json['variant'] as String?;
  Object? get label => _json['label'];
  List<JsonMap>? get checks => (_json['checks'] as List?)?.cast<JsonMap>();

  bool get enableDate {
    final String? v = variant;
    if (v == null) {
      if (_json.containsKey('enableDate')) return _json['enableDate'] as bool;
      return true;
    }
    return v == 'date' || v == 'datetime';
  }

  bool get enableTime {
    final String? v = variant;
    if (v == null) {
      if (_json.containsKey('enableTime')) return _json['enableTime'] as bool;
      return true;
    }
    return v == 'time' || v == 'datetime';
  }

  DateTime get firstDate =>
      DateTime.tryParse(
        (_json['min'] ?? _json['firstDate']) as String? ?? '',
      ) ??
      DateTime(-9999);
  DateTime get lastDate =>
      DateTime.tryParse((_json['max'] ?? _json['lastDate']) as String? ?? '') ??
      DateTime(9999, 12, 31);
}

class _DateTimeInput extends StatefulWidget {
  const _DateTimeInput({
    required this.value,
    required this.path,
    required this.data,
    required this.dataContext,
    required this.onChanged,
    this.label,
    this.checks,
    this.parser,
    super.key,
  });

  final String? value;
  final String path;
  final _DateTimeInputData data;
  final DataContext dataContext;
  final VoidCallback onChanged;
  final String? label;
  final List<JsonMap>? checks;
  final ExpressionParser? parser;

  @override
  State<_DateTimeInput> createState() => _DateTimeInputState();
}

class _DateTimeInputState extends State<_DateTimeInput> {
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _validate();
  }

  @override
  void didUpdateWidget(_DateTimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value || widget.checks != oldWidget.checks) {
      _validate();
    }
  }

  void _validate() {
    final String? newError = _calculateError();
    if (newError != _errorText) {
      setState(() {
        _errorText = newError;
      });
    }
  }

  String? _calculateError() {
    if (widget.checks == null || widget.parser == null) {
      return null;
    }

    for (final JsonMap check in widget.checks!) {
      final bool isValid = widget.parser!.evaluateLogic(check);
      if (!isValid) {
        return check['message'] as String? ?? 'Invalid value';
      }
    }
    return null;
  }

  Future<void> _handleTap(BuildContext context) async {
    final DateTime initialDate =
        DateTime.tryParse(widget.value ?? '') ??
        DateTime.tryParse('1970-01-01T${widget.value}') ??
        DateTime.now();

    var resultDate = initialDate;
    var resultTime = TimeOfDay.fromDateTime(initialDate);

    if (widget.data.enableDate) {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: widget.data.firstDate,
        lastDate: widget.data.lastDate,
      );
      if (pickedDate == null) {
        return;
      }
      resultDate = pickedDate;
    }

    if (widget.data.enableTime) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime == null) {
        return;
      }
      resultTime = pickedTime;
    }

    final finalDateTime = DateTime(
      resultDate.year,
      resultDate.month,
      resultDate.day,
      widget.data.enableTime ? resultTime.hour : 0,
      widget.data.enableTime ? resultTime.minute : 0,
    );

    String formattedValue;

    if (widget.data.enableDate && !widget.data.enableTime) {
      formattedValue = finalDateTime.toIso8601String().split('T').first;
    } else if (!widget.data.enableDate && widget.data.enableTime) {
      final String hour = finalDateTime.hour.toString().padLeft(2, '0');
      final String minute = finalDateTime.minute.toString().padLeft(2, '0');
      formattedValue = '$hour:$minute:00';
    } else {
      formattedValue = finalDateTime.toIso8601String();
    }

    widget.dataContext.update(DataPath(widget.path), formattedValue);
    widget.onChanged();
  }

  String _getDisplayText(MaterialLocalizations localizations) {
    if (widget.value == null) {
      return _getPlaceholderText();
    }

    final DateTime? date =
        DateTime.tryParse(widget.value!) ??
        DateTime.tryParse('1970-01-01T${widget.value}');

    if (date == null) {
      return widget.value!;
    }

    final List<String> parts = [
      if (widget.data.enableDate) localizations.formatFullDate(date),
      if (widget.data.enableTime)
        localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date)),
    ];
    return parts.join(' ');
  }

  String _getPlaceholderText() {
    if (widget.data.enableDate && widget.data.enableTime) {
      return 'Select a date and time';
    } else if (widget.data.enableDate) {
      return 'Select a date';
    } else if (widget.data.enableTime) {
      return 'Select a time';
    }
    return 'Select a date/time';
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final String displayText = _getDisplayText(localizations);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: _errorText,
        border: const OutlineInputBorder(),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Text(
          displayText,
          key: widget.key != null
              ? Key('${(widget.key as ValueKey<String>).value}_text')
              : null,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// A catalog item representing a Material Design date and/or time input field.
///
/// This widget displays a field that, when tapped, opens the native date and/or
/// time pickers. The selected value is stored as a string in the data model
/// path specified by the `value` parameter.
///
/// ## Parameters:
///
/// - `value`: The selected date and/or time, as a string.
/// - `enableDate`: Whether to allow the user to select a date. Defaults to
///   `true`.
/// - `enableTime`: Whether to allow the user to select a time. Defaults to
///   `true`.
/// - `min`: The minimum allowed date.
/// - `max`: The maximum allowed date.
/// - `label`: The label text.
/// - `checks`: Validation checks.
final dateTimeInput = CatalogItem(
  name: 'DateTimeInput',
  dataSchema: _schema,
  widgetBuilder: (itemContext) {
    final dateTimeInputData = _DateTimeInputData.fromMap(
      itemContext.data as JsonMap,
    );
    final Object valueRef = dateTimeInputData.value;
    final path = (valueRef is Map && valueRef.containsKey('path'))
        ? valueRef['path'] as String
        : '${itemContext.id}.value';

    final ValueNotifier<String?> valueNotifier = itemContext.dataContext
        .subscribeToString({'path': path});
    final ValueNotifier<String?> labelNotifier = itemContext.dataContext
        .subscribeToString(dateTimeInputData.label);

    final parser = ExpressionParser(itemContext.dataContext);

    return ValueListenableBuilder<String?>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        var effectiveValue = value;
        if (effectiveValue == null) {
          final Object val = dateTimeInputData.value;
          if (val is! Map || !val.containsKey('path')) {
            effectiveValue = val as String?;
          }
        }

        return ValueListenableBuilder<String?>(
          valueListenable: labelNotifier,
          builder: (context, label, child) {
            return _DateTimeInput(
              value: effectiveValue,
              path: path,
              data: dateTimeInputData,
              dataContext: itemContext.dataContext,
              onChanged: () {},
              label: label,
              checks: dateTimeInputData.checks,
              parser: parser,
              key: Key(itemContext.id),
            );
          },
        );
      },
    );
  },
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "DateTimeInput",
          "value": {
            "path": "/myDateTime"
          }
        }
      ]
    ''',
    () => '''
       [
        {
          "id": "root",
          "component": "DateTimeInput",
          "value": {
            "path": "/myDate"
          },
          "enableTime": false
        }
      ]
    ''',
    () => '''
      [
        {
          "id": "root",
          "component": "DateTimeInput",
          "value": {
            "path": "/myTime"
          },
          "enableDate": false
        }
      ]
    ''',
  ],
);
