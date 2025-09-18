// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../core/interpreter.dart';
import '../models/component.dart';

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
    return switch (properties) {
      TextProperties() => {'text': _resolveValue(properties.text, itemData)},
      HeadingProperties() => {
        'text': _resolveValue(properties.text, itemData),
        'level': properties.level,
      },
      ImageProperties() => {'url': _resolveValue(properties.url, itemData)},
      VideoProperties() => {'url': _resolveValue(properties.url, itemData)},
      AudioPlayerProperties() => {
        'url': _resolveValue(properties.url, itemData),
        'description': _resolveValue(properties.description, itemData),
      },
      ButtonProperties() => {
        'label': _resolveValue(properties.label, itemData),
        'action': properties.action,
      },
      CheckBoxProperties() => {
        'label': _resolveValue(properties.label, itemData),
        'value': _resolveValue(properties.value, itemData),
      },
      TextFieldProperties() => {
        'text': _resolveValue(properties.text, itemData),
        'label': _resolveValue(properties.label, itemData),
        'type': properties.type,
        'validationRegexp': properties.validationRegexp,
      },
      DateTimeInputProperties() => {
        'value': _resolveValue(properties.value, itemData),
        'enableDate': properties.enableDate,
        'enableTime': properties.enableTime,
        'outputFormat': properties.outputFormat,
      },
      MultipleChoiceProperties() => {
        'selections': _resolveValue(properties.selections, itemData),
        'options': properties.options,
        'maxAllowedSelections': properties.maxAllowedSelections,
      },
      SliderProperties() => {
        'value': _resolveValue(properties.value, itemData),
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

  Object? _resolveValue(BoundValue? value, Map<String, dynamic>? itemData) {
    if (value == null) {
      return null;
    }
    if (value.literalString != null) {
      return value.literalString;
    } else if (value.literalNumber != null) {
      return value.literalNumber;
    } else if (value.literalBoolean != null) {
      return value.literalBoolean;
    } else if (value.path != null) {
      if (itemData != null) {
        return itemData[value.path!];
      } else {
        return interpreter.resolveDataBinding(value.path!);
      }
    }
    return null;
  }
}
