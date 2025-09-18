// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class Component {
  const Component({
    required this.id,
    this.weight,
    required this.componentProperties,
  });

  final String id;
  final double? weight;
  final ComponentProperties componentProperties;
}

sealed class ComponentProperties {
  factory ComponentProperties.fromJson(Map<String, dynamic> json) {
    // TODO(gspencer): implement fromJson
    throw UnimplementedError();
  }
}

class HeadingProperties implements ComponentProperties {
  const HeadingProperties({required this.text, required this.level});

  final BoundValue text;
  final String level;
}

class TextProperties implements ComponentProperties {
  const TextProperties({required this.text});

  final BoundValue text;
}

class ImageProperties implements ComponentProperties {
  const ImageProperties({required this.url});

  final BoundValue url;
}

class VideoProperties implements ComponentProperties {
  const VideoProperties({required this.url});

  final BoundValue url;
}

class AudioPlayerProperties implements ComponentProperties {
  const AudioPlayerProperties({required this.url, this.description});

  final BoundValue url;
  final BoundValue? description;
}

class RowProperties implements ComponentProperties {
  const RowProperties({
    required this.children,
    this.distribution,
    this.alignment,
  });

  final Children children;
  final String? distribution;
  final String? alignment;
}

class ColumnProperties implements ComponentProperties {
  const ColumnProperties({
    required this.children,
    this.distribution,
    this.alignment,
  });

  final Children children;
  final String? distribution;
  final String? alignment;
}

class ListProperties implements ComponentProperties {
  const ListProperties({
    required this.children,
    this.direction,
    this.alignment,
  });

  final Children children;
  final String? direction;
  final String? alignment;
}

class CardProperties implements ComponentProperties {
  const CardProperties({required this.child});

  final String child;
}

class TabsProperties implements ComponentProperties {
  const TabsProperties({required this.tabItems});

  final List<TabItem> tabItems;
}

class DividerProperties implements ComponentProperties {
  const DividerProperties({this.axis, this.color, this.thickness});

  final String? axis;
  final String? color;
  final double? thickness;
}

class ModalProperties implements ComponentProperties {
  const ModalProperties({
    required this.entryPointChild,
    required this.contentChild,
  });

  final String entryPointChild;
  final String contentChild;
}

class ButtonProperties implements ComponentProperties {
  const ButtonProperties({required this.label, required this.action});

  final BoundValue label;
  final Action action;
}

class CheckBoxProperties implements ComponentProperties {
  const CheckBoxProperties({required this.label, required this.value});

  final BoundValue label;
  final BoundValue value;
}

class TextFieldProperties implements ComponentProperties {
  const TextFieldProperties({
    this.text,
    required this.label,
    this.type,
    this.validationRegexp,
  });

  final BoundValue? text;
  final BoundValue label;
  final String? type;
  final String? validationRegexp;
}

class DateTimeInputProperties implements ComponentProperties {
  const DateTimeInputProperties({
    required this.value,
    this.enableDate,
    this.enableTime,
    this.outputFormat,
  });

  final BoundValue value;
  final bool? enableDate;
  final bool? enableTime;
  final String? outputFormat;
}

class MultipleChoiceProperties implements ComponentProperties {
  const MultipleChoiceProperties({
    required this.selections,
    this.options,
    this.maxAllowedSelections,
  });

  final BoundValue selections;
  final List<Option>? options;
  final int? maxAllowedSelections;
}

class SliderProperties implements ComponentProperties {
  const SliderProperties({required this.value, this.minValue, this.maxValue});

  final BoundValue value;
  final double? minValue;
  final double? maxValue;
}

class BoundValue {
  const BoundValue({
    this.path,
    this.literalString,
    this.literalNumber,
    this.literalBoolean,
  });

  final String? path;
  final String? literalString;
  final double? literalNumber;
  final bool? literalBoolean;
}

class Children {
  const Children({this.explicitList, this.template});

  final List<String>? explicitList;
  final Template? template;
}

class Template {
  const Template({required this.componentId, required this.dataBinding});

  final String componentId;
  final String dataBinding;
}

class TabItem {
  const TabItem({required this.title, required this.child});

  final BoundValue title;
  final String child;
}

class Action {
  const Action({required this.action, this.context});

  final String action;
  final List<ContextItem>? context;
}

class ContextItem {
  const ContextItem({required this.key, required this.value});

  final String key;
  final BoundValue value;
}

class Option {
  const Option({required this.label, required this.value});

  final BoundValue label;
  final String value;
}
