// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class Component {
  const Component({
    required this.id,
    this.weight,
    required this.componentProperties,
  });

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      id: json['id'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      componentProperties: ComponentProperties.fromJson(
        json['componentProperties'] as Map<String, dynamic>,
      ),
    );
  }

  final String id;
  final double? weight;
  final ComponentProperties componentProperties;
}

sealed class ComponentProperties {
  factory ComponentProperties.fromJson(Map<String, dynamic> json) {
    final type = json.keys.first;
    final properties = json[type] as Map<String, dynamic>;
    switch (type) {
      case 'Heading':
        return HeadingProperties.fromJson(properties);
      case 'Text':
        return TextProperties.fromJson(properties);
      case 'Image':
        return ImageProperties.fromJson(properties);
      case 'Video':
        return VideoProperties.fromJson(properties);
      case 'AudioPlayer':
        return AudioPlayerProperties.fromJson(properties);
      case 'Row':
        return RowProperties.fromJson(properties);
      case 'Column':
        return ColumnProperties.fromJson(properties);
      case 'List':
        return ListProperties.fromJson(properties);
      case 'Card':
        return CardProperties.fromJson(properties);
      case 'Tabs':
        return TabsProperties.fromJson(properties);
      case 'Divider':
        return DividerProperties.fromJson(properties);
      case 'Modal':
        return ModalProperties.fromJson(properties);
      case 'Button':
        return ButtonProperties.fromJson(properties);
      case 'CheckBox':
        return CheckBoxProperties.fromJson(properties);
      case 'TextField':
        return TextFieldProperties.fromJson(properties);
      case 'DateTimeInput':
        return DateTimeInputProperties.fromJson(properties);
      case 'MultipleChoice':
        return MultipleChoiceProperties.fromJson(properties);
      case 'Slider':
        return SliderProperties.fromJson(properties);
      default:
        throw Exception('Unknown component type: $type');
    }
  }
}

class HeadingProperties implements ComponentProperties {
  const HeadingProperties({required this.text, required this.level});

  factory HeadingProperties.fromJson(Map<String, dynamic> json) {
    return HeadingProperties(
      text: BoundValue.fromJson(json['text'] as Map<String, dynamic>),
      level: json['level'] as String,
    );
  }

  final BoundValue text;
  final String level;
}

class TextProperties implements ComponentProperties {
  const TextProperties({required this.text});

  factory TextProperties.fromJson(Map<String, dynamic> json) {
    return TextProperties(
      text: BoundValue.fromJson(json['text'] as Map<String, dynamic>),
    );
  }

  final BoundValue text;
}

class ImageProperties implements ComponentProperties {
  const ImageProperties({required this.url});

  factory ImageProperties.fromJson(Map<String, dynamic> json) {
    return ImageProperties(
      url: BoundValue.fromJson(json['url'] as Map<String, dynamic>),
    );
  }

  final BoundValue url;
}

class VideoProperties implements ComponentProperties {
  const VideoProperties({required this.url});

  factory VideoProperties.fromJson(Map<String, dynamic> json) {
    return VideoProperties(
      url: BoundValue.fromJson(json['url'] as Map<String, dynamic>),
    );
  }

  final BoundValue url;
}

class AudioPlayerProperties implements ComponentProperties {
  const AudioPlayerProperties({required this.url, this.description});

  factory AudioPlayerProperties.fromJson(Map<String, dynamic> json) {
    return AudioPlayerProperties(
      url: BoundValue.fromJson(json['url'] as Map<String, dynamic>),
      description: json['description'] != null
          ? BoundValue.fromJson(json['description'] as Map<String, dynamic>)
          : null,
    );
  }

  final BoundValue url;
  final BoundValue? description;
}

class RowProperties implements ComponentProperties {
  const RowProperties({
    required this.children,
    this.distribution,
    this.alignment,
  });

  factory RowProperties.fromJson(Map<String, dynamic> json) {
    return RowProperties(
      children: Children.fromJson(json['children'] as Map<String, dynamic>),
      distribution: json['distribution'] as String?,
      alignment: json['alignment'] as String?,
    );
  }

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

  factory ColumnProperties.fromJson(Map<String, dynamic> json) {
    return ColumnProperties(
      children: Children.fromJson(json['children'] as Map<String, dynamic>),
      distribution: json['distribution'] as String?,
      alignment: json['alignment'] as String?,
    );
  }

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

  factory ListProperties.fromJson(Map<String, dynamic> json) {
    return ListProperties(
      children: Children.fromJson(json['children'] as Map<String, dynamic>),
      direction: json['direction'] as String?,
      alignment: json['alignment'] as String?,
    );
  }

  final Children children;
  final String? direction;
  final String? alignment;
}

class CardProperties implements ComponentProperties {
  const CardProperties({required this.child});

  factory CardProperties.fromJson(Map<String, dynamic> json) {
    return CardProperties(child: json['child'] as String);
  }

  final String child;
}

class TabsProperties implements ComponentProperties {
  const TabsProperties({required this.tabItems});

  factory TabsProperties.fromJson(Map<String, dynamic> json) {
    return TabsProperties(
      tabItems: (json['tabItems'] as List<dynamic>)
          .map((e) => TabItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<TabItem> tabItems;
}

class DividerProperties implements ComponentProperties {
  const DividerProperties({this.axis, this.color, this.thickness});

  factory DividerProperties.fromJson(Map<String, dynamic> json) {
    return DividerProperties(
      axis: json['axis'] as String?,
      color: json['color'] as String?,
      thickness: (json['thickness'] as num?)?.toDouble(),
    );
  }

  final String? axis;
  final String? color;
  final double? thickness;
}

class ModalProperties implements ComponentProperties {
  const ModalProperties({
    required this.entryPointChild,
    required this.contentChild,
  });

  factory ModalProperties.fromJson(Map<String, dynamic> json) {
    return ModalProperties(
      entryPointChild: json['entryPointChild'] as String,
      contentChild: json['contentChild'] as String,
    );
  }

  final String entryPointChild;
  final String contentChild;
}

class ButtonProperties implements ComponentProperties {
  const ButtonProperties({required this.label, required this.action});

  factory ButtonProperties.fromJson(Map<String, dynamic> json) {
    return ButtonProperties(
      label: BoundValue.fromJson(json['label'] as Map<String, dynamic>),
      action: Action.fromJson(json['action'] as Map<String, dynamic>),
    );
  }

  final BoundValue label;
  final Action action;
}

class CheckBoxProperties implements ComponentProperties {
  const CheckBoxProperties({required this.label, required this.value});

  factory CheckBoxProperties.fromJson(Map<String, dynamic> json) {
    return CheckBoxProperties(
      label: BoundValue.fromJson(json['label'] as Map<String, dynamic>),
      value: BoundValue.fromJson(json['value'] as Map<String, dynamic>),
    );
  }

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

  factory TextFieldProperties.fromJson(Map<String, dynamic> json) {
    return TextFieldProperties(
      text: json['text'] != null
          ? BoundValue.fromJson(json['text'] as Map<String, dynamic>)
          : null,
      label: BoundValue.fromJson(json['label'] as Map<String, dynamic>),
      type: json['type'] as String?,
      validationRegexp: json['validationRegexp'] as String?,
    );
  }

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

  factory DateTimeInputProperties.fromJson(Map<String, dynamic> json) {
    return DateTimeInputProperties(
      value: BoundValue.fromJson(json['value'] as Map<String, dynamic>),
      enableDate: json['enableDate'] as bool?,
      enableTime: json['enableTime'] as bool?,
      outputFormat: json['outputFormat'] as String?,
    );
  }

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

  factory MultipleChoiceProperties.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceProperties(
      selections: BoundValue.fromJson(
        json['selections'] as Map<String, dynamic>,
      ),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => Option.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxAllowedSelections: json['maxAllowedSelections'] as int?,
    );
  }

  final BoundValue selections;
  final List<Option>? options;
  final int? maxAllowedSelections;
}

class SliderProperties implements ComponentProperties {
  const SliderProperties({required this.value, this.minValue, this.maxValue});

  factory SliderProperties.fromJson(Map<String, dynamic> json) {
    return SliderProperties(
      value: BoundValue.fromJson(json['value'] as Map<String, dynamic>),
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
    );
  }

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

  factory BoundValue.fromJson(Map<String, dynamic> json) {
    return BoundValue(
      path: json['path'] as String?,
      literalString: json['literalString'] as String?,
      literalNumber: (json['literalNumber'] as num?)?.toDouble(),
      literalBoolean: json['literalBoolean'] as bool?,
    );
  }

  final String? path;
  final String? literalString;
  final double? literalNumber;
  final bool? literalBoolean;
}

class Children {
  const Children({this.explicitList, this.template});

  factory Children.fromJson(Map<String, dynamic> json) {
    return Children(
      explicitList: (json['explicitList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      template: json['template'] != null
          ? Template.fromJson(json['template'] as Map<String, dynamic>)
          : null,
    );
  }

  final List<String>? explicitList;
  final Template? template;
}

class Template {
  const Template({required this.componentId, required this.dataBinding});

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      componentId: json['componentId'] as String,
      dataBinding: json['dataBinding'] as String,
    );
  }

  final String componentId;
  final String dataBinding;
}

class TabItem {
  const TabItem({required this.title, required this.child});

  factory TabItem.fromJson(Map<String, dynamic> json) {
    return TabItem(
      title: BoundValue.fromJson(json['title'] as Map<String, dynamic>),
      child: json['child'] as String,
    );
  }

  final BoundValue title;
  final String child;
}

class Action {
  const Action({required this.action, this.context});

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      action: json['action'] as String,
      context: (json['context'] as List<dynamic>?)
          ?.map((e) => ContextItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String action;
  final List<ContextItem>? context;
}

class ContextItem {
  const ContextItem({required this.key, required this.value});

  factory ContextItem.fromJson(Map<String, dynamic> json) {
    return ContextItem(
      key: json['key'] as String,
      value: BoundValue.fromJson(json['value'] as Map<String, dynamic>),
    );
  }

  final String key;
  final BoundValue value;
}

class Option {
  const Option({required this.label, required this.value});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      label: BoundValue.fromJson(json['label'] as Map<String, dynamic>),
      value: json['value'] as String,
    );
  }

  final BoundValue label;
  final String value;
}
