// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart';

import '../core/interpreter.dart';
import '../models/component.dart';

final _log = Logger('ComponentPropertiesVisitor');

/// A visitor that resolves the properties of a [Component].
class ComponentPropertiesVisitor {
  /// Creates a new [ComponentPropertiesVisitor].
  const ComponentPropertiesVisitor(this.interpreter);

  /// The interpreter to use for resolving data bindings.
  final GulfInterpreter interpreter;

  /// Resolves the properties of a [Component].
  Map<String, Object?> visit(
    ComponentProperties properties,
    Map<String, dynamic>? itemData,
  ) {
    _log.finer('Visiting ${properties.runtimeType} with itemData: $itemData');
    return switch (properties) {
      TextProperties() => {'text': resolveValue(properties.text, itemData)},
      HeadingProperties() => {
        'text': resolveValue(properties.text, itemData),
        'level': properties.level,
      },
      ImageProperties() => {'url': resolveValue(properties.url, itemData)},
      VideoProperties() => {'url': resolveValue(properties.url, itemData)},
      AudioPlayerProperties() => {
        'url': resolveValue(properties.url, itemData),
        'description': resolveValue(properties.description, itemData),
      },
      ButtonProperties() => {
        'label': resolveValue(properties.label, itemData),
        'action': properties.action,
      },
      CheckBoxProperties() => {
        'label': resolveValue(properties.label, itemData),
        'value': resolveValue(properties.value, itemData),
      },
      TextFieldProperties() => {
        'text': resolveValue(properties.text, itemData),
        'label': resolveValue(properties.label, itemData),
        'type': properties.type,
        'validationRegexp': properties.validationRegexp,
      },
      DateTimeInputProperties() => {
        'value': resolveValue(properties.value, itemData),
        'enableDate': properties.enableDate,
        'enableTime': properties.enableTime,
        'outputFormat': properties.outputFormat,
      },
      MultipleChoiceProperties() => {
        'selections': resolveValue(properties.selections, itemData),
        'options': properties.options,
        'maxAllowedSelections': properties.maxAllowedSelections,
      },
      SliderProperties() => {
        'value': resolveValue(properties.value, itemData),
        'minValue': properties.minValue,
        'maxValue': properties.maxValue,
      },
      RowProperties() => {},
      ColumnProperties() => {},
      ListProperties() => {},
      CardProperties() => {},
      TabsProperties() => {},
      DividerProperties() => {},
      ModalProperties() => {},
    };
  }

  Object? resolveValue(BoundValue? value, Map<String, dynamic>? itemData) {
    if (value == null) {
      return null;
    }
    _log.finest('Resolving bound value: $value with itemData: $itemData');
    if (value.literalString != null) {
      return value.literalString;
    } else if (value.literalNumber != null) {
      return value.literalNumber;
    } else if (value.literalBoolean != null) {
      return value.literalBoolean;
    } else if (value.path != null) {
      Object? resolvedValue;
      if (itemData != null) {
        resolvedValue = itemData[value.path!];
        _log.finest(
          'Resolved path "${value.path}" from itemData to: $resolvedValue',
        );
      } else {
        resolvedValue = interpreter.resolveDataBinding(value.path!);
        _log.finest(
          'Resolved path "${value.path}" from interpreter to: $resolvedValue',
        );
      }
      return resolvedValue;
    }
    return null;
  }
}
