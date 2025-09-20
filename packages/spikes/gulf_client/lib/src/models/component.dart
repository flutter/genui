// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';

/// An exception that is thrown when an unknown component type is encountered.
class UnknownComponentException implements Exception {
  UnknownComponentException(this.type);

  /// The unknown component type.
  final String type;

  @override
  String toString() => 'Unknown component: $type';
}

/// A component in the UI.
class Component extends Equatable {
  const Component({
    required this.id,
    this.weight,
    required this.componentProperties,
  });

  /// Creates a [Component] from a JSON object.
  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      id: json['id'] as String,
      weight: JsonUtils.parseDouble(json['weight']),
      componentProperties: ComponentProperties.fromJson(
        json['componentProperties'] as Map<String, dynamic>,
      ),
    );
  }

  /// The unique ID of the component.
  final String id;

  /// The weight of the component in a layout.
  final double? weight;

  /// The properties of the component.
  final ComponentProperties componentProperties;

  @override
  List<Object?> get props => [id, weight, componentProperties];
}

/// A sealed class for the properties of a component.
sealed class ComponentProperties extends Equatable {
  const ComponentProperties();

  /// Creates a [ComponentProperties] from a JSON object.
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
        throw UnknownComponentException(type);
    }
  }

  @override
  List<Object?> get props => [];

  /// The type of the component.
  String get componentType;
}

/// An interface for components that have children.
abstract class HasChildren {
  /// The children of the component.
  Children get children;
}

/// The properties for a heading component.
class HeadingProperties extends ComponentProperties {
  const HeadingProperties({required this.text, required this.level});

  factory HeadingProperties.fromJson(Map<String, dynamic> json) {
    return HeadingProperties(
      text: BoundValue.fromJson(json['text'] as Map<String, dynamic>),
      level: json['level'] as String,
    );
  }

  /// The text of the heading.
  final BoundValue text;

  /// The level of the heading.
  final String level;

  @override
  List<Object?> get props => [text, level];

  @override
  String get componentType => 'Heading';
}

/// The properties for a text component.
class TextProperties extends ComponentProperties {
  const TextProperties({required this.text});

  factory TextProperties.fromJson(Map<String, dynamic> json) {
    return TextProperties(
      text: BoundValue.fromJson(json['text'] as Map<String, dynamic>),
    );
  }

  /// The text of the component.
  final BoundValue text;

  @override
  List<Object?> get props => [text];

  @override
  String get componentType => 'Text';
}

/// The properties for an image component.
class ImageProperties extends ComponentProperties {
  const ImageProperties({required this.url});

  factory ImageProperties.fromJson(Map<String, dynamic> json) {
    return ImageProperties(
      url: BoundValue.fromJson(json['url'] as Map<String, dynamic>),
    );
  }

  /// The URL of the image.
  final BoundValue url;

  @override
  List<Object?> get props => [url];

  @override
  String get componentType => 'Image';
}

/// The properties for a video component.
class VideoProperties extends ComponentProperties {
  const VideoProperties({required this.url});

  factory VideoProperties.fromJson(Map<String, dynamic> json) {
    return VideoProperties(
      url: BoundValue.fromJson(json['url'] as Map<String, dynamic>),
    );
  }

  /// The URL of the video.
  final BoundValue url;

  @override
  List<Object?> get props => [url];

  @override
  String get componentType => 'Video';
}

/// The properties for an audio player component.
class AudioPlayerProperties extends ComponentProperties {
  const AudioPlayerProperties({required this.url, this.description});

  factory AudioPlayerProperties.fromJson(Map<String, dynamic> json) {
    return AudioPlayerProperties(
      url: BoundValue.fromJson(json['url'] as Map<String, dynamic>),
      description: json['description'] != null
          ? BoundValue.fromJson(json['description'] as Map<String, dynamic>)
          : null,
    );
  }

  /// The URL of the audio.
  final BoundValue url;

  /// The description of the audio.
  final BoundValue? description;

  @override
  List<Object?> get props => [url, description];

  @override
  String get componentType => 'AudioPlayer';
}

/// The properties for a row component.
class RowProperties extends ComponentProperties implements HasChildren {
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

  @override
  final Children children;

  /// The distribution of the children in the row.
  final String? distribution;

  /// The alignment of the children in the row.
  final String? alignment;

  @override
  List<Object?> get props => [children, distribution, alignment];

  @override
  String get componentType => 'Row';
}

/// The properties for a column component.
class ColumnProperties extends ComponentProperties implements HasChildren {
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

  @override
  final Children children;

  /// The distribution of the children in the column.
  final String? distribution;

  /// The alignment of the children in the column.
  final String? alignment;

  @override
  List<Object?> get props => [children, distribution, alignment];

  @override
  String get componentType => 'Column';
}

/// The properties for a list component.
class ListProperties extends ComponentProperties implements HasChildren {
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

  @override
  final Children children;

  /// The direction of the list.
  final String? direction;

  /// The alignment of the children in the list.
  final String? alignment;

  @override
  List<Object?> get props => [children, direction, alignment];

  @override
  String get componentType => 'List';
}

/// The properties for a card component.
class CardProperties extends ComponentProperties {
  const CardProperties({required this.child});

  factory CardProperties.fromJson(Map<String, dynamic> json) {
    return CardProperties(child: json['child'] as String);
  }

  /// The child of the card.
  final String child;

  @override
  List<Object?> get props => [child];

  @override
  String get componentType => 'Card';
}

/// The properties for a tabs component.
class TabsProperties extends ComponentProperties {
  const TabsProperties({required this.tabItems});

  factory TabsProperties.fromJson(Map<String, dynamic> json) {
    return TabsProperties(
      tabItems: (json['tabItems'] as List<dynamic>)
          .map((e) => TabItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The items in the tab bar.
  final List<TabItem> tabItems;

  @override
  List<Object?> get props => [tabItems];

  @override
  String get componentType => 'Tabs';
}

/// The properties for a divider component.
class DividerProperties extends ComponentProperties {
  const DividerProperties({this.axis, this.color, this.thickness});

  factory DividerProperties.fromJson(Map<String, dynamic> json) {
    return DividerProperties(
      axis: json['axis'] as String?,
      color: json['color'] as String?,
      thickness: JsonUtils.parseDouble(json['thickness']),
    );
  }

  /// The axis of the divider.
  final String? axis;

  /// The color of the divider.
  final String? color;

  /// The thickness of the divider.
  final double? thickness;

  @override
  List<Object?> get props => [axis, color, thickness];

  @override
  String get componentType => 'Divider';
}

/// The properties for a modal component.
class ModalProperties extends ComponentProperties {
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

  /// The child that triggers the modal.
  final String entryPointChild;

  /// The child that is displayed in the modal.
  final String contentChild;

  @override
  List<Object?> get props => [entryPointChild, contentChild];

  @override
  String get componentType => 'Modal';
}

/// The properties for a button component.
class ButtonProperties extends ComponentProperties {
  const ButtonProperties({required this.label, required this.action});

  factory ButtonProperties.fromJson(Map<String, dynamic> json) {
    return ButtonProperties(
      label: BoundValue.fromJson(json['label'] as Map<String, dynamic>),
      action: Action.fromJson(json['action'] as Map<String, dynamic>),
    );
  }

  /// The label of the button.
  final BoundValue label;

  /// The action to perform when the button is tapped.
  final Action action;

  @override
  List<Object?> get props => [label, action];

  @override
  String get componentType => 'Button';
}

/// The properties for a checkbox component.
class CheckBoxProperties extends ComponentProperties {
  const CheckBoxProperties({required this.label, required this.value});

  factory CheckBoxProperties.fromJson(Map<String, dynamic> json) {
    return CheckBoxProperties(
      label: BoundValue.fromJson(json['label'] as Map<String, dynamic>),
      value: BoundValue.fromJson(json['value'] as Map<String, dynamic>),
    );
  }

  /// The label of the checkbox.
  final BoundValue label;

  /// The value of the checkbox.
  final BoundValue value;

  @override
  List<Object?> get props => [label, value];

  @override
  String get componentType => 'CheckBox';
}

/// The properties for a text field component.
class TextFieldProperties extends ComponentProperties {
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

  /// The text of the text field.
  final BoundValue? text;

  /// The label of the text field.
  final BoundValue label;

  /// The type of the text field.
  final String? type;

  /// The validation regular expression for the text field.
  final String? validationRegexp;

  @override
  List<Object?> get props => [text, label, type, validationRegexp];

  @override
  String get componentType => 'TextField';
}

/// The properties for a date/time input component.
class DateTimeInputProperties extends ComponentProperties {
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

  /// The value of the date/time input.
  final BoundValue value;

  /// Whether to enable the date picker.
  final bool? enableDate;

  /// Whether to enable the time picker.
  final bool? enableTime;

  /// The output format of the date/time input.
  final String? outputFormat;

  @override
  List<Object?> get props => [value, enableDate, enableTime, outputFormat];

  @override
  String get componentType => 'DateTimeInput';
}

/// The properties for a multiple choice component.
class MultipleChoiceProperties extends ComponentProperties {
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

  /// The selected values.
  final BoundValue selections;

  /// The options for the multiple choice component.
  final List<Option>? options;

  /// The maximum number of allowed selections.
  final int? maxAllowedSelections;

  @override
  List<Object?> get props => [selections, options, maxAllowedSelections];

  @override
  String get componentType => 'MultipleChoice';
}

/// The properties for a slider component.
class SliderProperties extends ComponentProperties {
  const SliderProperties({required this.value, this.minValue, this.maxValue});

  factory SliderProperties.fromJson(Map<String, dynamic> json) {
    return SliderProperties(
      value: BoundValue.fromJson(json['value'] as Map<String, dynamic>),
      minValue: JsonUtils.parseDouble(json['minValue']),
      maxValue: JsonUtils.parseDouble(json['maxValue']),
    );
  }

  /// The value of the slider.
  final BoundValue value;

  /// The minimum value of the slider.
  final double? minValue;

  /// The maximum value of the slider.
  final double? maxValue;

  @override
  List<Object?> get props => [value, minValue, maxValue];

  @override
  String get componentType => 'Slider';
}

/// A value that can be either a literal or a data binding.
class BoundValue extends Equatable {
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
      literalNumber: JsonUtils.parseDouble(json['literalNumber']),
      literalBoolean: json['literalBoolean'] as bool?,
    );
  }

  /// The path to the value in the data model.
  final String? path;

  /// The literal string value.
  final String? literalString;

  /// The literal number value.
  final double? literalNumber;

  /// The literal boolean value.
  final bool? literalBoolean;

  @override
  List<Object?> get props => [
    path,
    literalString,
    literalNumber,
    literalBoolean,
  ];
}

/// The children of a component.
class Children extends Equatable {
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

  /// The explicit list of children.
  final List<String>? explicitList;

  /// The template for the children.
  final Template? template;

  @override
  List<Object?> get props => [explicitList, template];
}

/// A template for a list of children.
class Template extends Equatable {
  const Template({required this.componentId, required this.dataBinding});

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      componentId: json['componentId'] as String,
      dataBinding: json['dataBinding'] as String,
    );
  }

  /// The ID of the component to use as a template.
  final String componentId;

  /// The data binding for the template.
  final String dataBinding;

  @override
  List<Object?> get props => [componentId, dataBinding];
}

/// An item in a tab bar.
class TabItem extends Equatable {
  const TabItem({required this.title, required this.child});

  factory TabItem.fromJson(Map<String, dynamic> json) {
    return TabItem(
      title: BoundValue.fromJson(json['title'] as Map<String, dynamic>),
      child: json['child'] as String,
    );
  }

  /// The title of the tab.
  final BoundValue title;

  /// The child of the tab.
  final String child;

  @override
  List<Object?> get props => [title, child];
}

/// An action to perform when a widget is interacted with.
class Action extends Equatable {
  const Action({required this.action, this.context});

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      action: json['action'] as String,
      context: (json['context'] as List<dynamic>?)
          ?.map((e) => ContextItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The name of the action.
  final String action;

  /// The context of the action.
  final List<ContextItem>? context;

  @override
  List<Object?> get props => [action, context];
}

/// An item in the context of an action.
class ContextItem extends Equatable {
  const ContextItem({required this.key, required this.value});

  factory ContextItem.fromJson(Map<String, dynamic> json) {
    return ContextItem(
      key: json['key'] as String,
      value: BoundValue.fromJson(json['value'] as Map<String, dynamic>),
    );
  }

  /// The key of the context item.
  final String key;

  /// The value of the context item.
  final BoundValue value;

  @override
  List<Object?> get props => [key, value];
}

/// An option in a multiple choice component.
class Option extends Equatable {
  const Option({required this.label, required this.value});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      label: BoundValue.fromJson(json['label'] as Map<String, dynamic>),
      value: json['value'] as String,
    );
  }

  /// The label of the option.
  final BoundValue label;

  /// The value of the option.
  final String value;

  @override
  List<Object?> get props => [label, value];
}
