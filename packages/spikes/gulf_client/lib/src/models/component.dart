// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

class Component {
  const Component({
    required this.id,
    required this.type,
    this.value,
    this.level,
    this.description,
    this.direction,
    this.children,
    this.distribution,
    this.alignment,
    this.child,
    this.tabItems,
    this.axis,
    this.color,
    this.thickness,
    this.entryPointChild,
    this.contentChild,
    this.label,
    this.action,
    this.textFieldType,
    this.validationRegexp,
    this.enableDate = true,
    this.enableTime = false,
    this.outputFormat,
    this.options,
    this.maxAllowedSelections = 1,
    this.minValue = 0,
    this.maxValue = 100,
  });

  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      id: json['id'] as String,
      type: json['type'] as String,
      value: json['value'] != null
          ? Value.fromJson(json['value'] as Map<String, dynamic>)
          : null,
      level: json['level'] as int?,
      description: json['description'] as String?,
      direction: json['direction'] as String?,
      children: json['children'] != null
          ? Children.fromJson(json['children'] as Map<String, dynamic>)
          : null,
      distribution: json['distribution'] as String?,
      alignment: json['alignment'] as String?,
      child: json['child'] as String?,
      tabItems: (json['tabItems'] as List<dynamic>?)
          ?.map((e) => TabItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      axis: json['axis'] as String?,
      color: json['color'] as String?,
      thickness: (json['thickness'] as num?)?.toDouble(),
      entryPointChild: json['entryPointChild'] as String?,
      contentChild: json['contentChild'] as String?,
      label: json['label'] as String?,
      action: json['action'] != null
          ? Action.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      textFieldType: json['textFieldType'] as String?,
      validationRegexp: json['validationRegexp'] as String?,
      enableDate: json['enableDate'] as bool? ?? true,
      enableTime: json['enableTime'] as bool? ?? false,
      outputFormat: json['outputFormat'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => Option.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxAllowedSelections: json['maxAllowedSelections'] as int? ?? 1,
      minValue: (json['min_value'] as num?)?.toDouble() ?? 0,
      maxValue: (json['max_value'] as num?)?.toDouble() ?? 100,
    );
  }

  final String id;
  final String type;
  final Value? value;
  final int? level;
  final String? description;
  final String? direction;
  final Children? children;
  final String? distribution;
  final String? alignment;
  final String? child;
  final List<TabItem>? tabItems;
  final String? axis;
  final String? color;
  final double? thickness;
  final String? entryPointChild;
  final String? contentChild;
  final String? label;
  final Action? action;
  final String? textFieldType;
  final String? validationRegexp;
  final bool enableDate;
  final bool enableTime;
  final String? outputFormat;
  final List<Option>? options;
  final int maxAllowedSelections;
  final double minValue;
  final double maxValue;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      if (value != null) 'value': value!.toJson(),
      if (level != null) 'level': level,
      if (description != null) 'description': description,
      if (direction != null) 'direction': direction,
      if (children != null) 'children': children!.toJson(),
      if (distribution != null) 'distribution': distribution,
      if (alignment != null) 'alignment': alignment,
      if (child != null) 'child': child,
      if (tabItems != null)
        'tabItems': tabItems!.map((e) => e.toJson()).toList(),
      if (axis != null) 'axis': axis,
      if (color != null) 'color': color,
      if (thickness != null) 'thickness': thickness,
      if (entryPointChild != null) 'entryPointChild': entryPointChild,
      if (contentChild != null) 'contentChild': contentChild,
      if (label != null) 'label': label,
      if (action != null) 'action': action!.toJson(),
      if (textFieldType != null) 'textFieldType': textFieldType,
      if (validationRegexp != null) 'validationRegexp': validationRegexp,
      'enableDate': enableDate,
      'enableTime': enableTime,
      if (outputFormat != null) 'outputFormat': outputFormat,
      if (options != null) 'options': options!.map((e) => e.toJson()).toList(),
      'maxAllowedSelections': maxAllowedSelections,
      'min_value': minValue,
      'max_value': maxValue,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Component &&
        other.id == id &&
        other.type == type &&
        other.value == value &&
        other.level == level &&
        other.description == description &&
        other.direction == direction &&
        other.children == children &&
        other.distribution == distribution &&
        other.alignment == alignment &&
        other.child == child &&
        listEquals(other.tabItems, tabItems) &&
        other.axis == axis &&
        other.color == color &&
        other.thickness == thickness &&
        other.entryPointChild == entryPointChild &&
        other.contentChild == contentChild &&
        other.label == label &&
        other.action == action &&
        other.textFieldType == textFieldType &&
        other.validationRegexp == validationRegexp &&
        other.enableDate == enableDate &&
        other.enableTime == enableTime &&
        other.outputFormat == outputFormat &&
        listEquals(other.options, options) &&
        other.maxAllowedSelections == maxAllowedSelections &&
        other.minValue == minValue &&
        other.maxValue == maxValue;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    type,
    value,
    level,
    description,
    direction,
    children,
    distribution,
    alignment,
    child,
    tabItems,
    axis,
    color,
    thickness,
    entryPointChild,
    contentChild,
    label,
    action,
    textFieldType,
    validationRegexp,
    enableDate,
    enableTime,
    outputFormat,
    options,
    maxAllowedSelections,
    minValue,
    maxValue,
  ]);
}

class Value {
  const Value({
    this.path,
    this.literalString,
    this.literalNumber,
    this.literalBoolean,
    this.literalObject,
    this.literalArray,
  });

  factory Value.fromJson(Map<String, dynamic> json) {
    return Value(
      path: json['path'] as String?,
      literalString: json['literalString'] as String?,
      literalNumber: (json['literalNumber'] as num?)?.toDouble(),
      literalBoolean: json['literalBoolean'] as bool?,
      literalObject: json['literalObject'] as Map<String, dynamic>?,
      literalArray: json['literalArray'] as List<dynamic>?,
    );
  }

  final String? path;
  final String? literalString;
  final double? literalNumber;
  final bool? literalBoolean;
  final Map<String, dynamic>? literalObject;
  final List<dynamic>? literalArray;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (path != null) 'path': path,
      if (literalString != null) 'literalString': literalString,
      if (literalNumber != null) 'literalNumber': literalNumber,
      if (literalBoolean != null) 'literalBoolean': literalBoolean,
      if (literalObject != null) 'literalObject': literalObject,
      if (literalArray != null) 'literalArray': literalArray,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Value &&
        other.path == path &&
        other.literalString == literalString &&
        other.literalNumber == literalNumber &&
        other.literalBoolean == literalBoolean &&
        mapEquals(other.literalObject, literalObject) &&
        listEquals(other.literalArray, literalArray);
  }

  @override
  int get hashCode {
    return Object.hash(
      path,
      literalString,
      literalNumber,
      literalBoolean,
      literalObject,
      literalArray,
    );
  }
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (explicitList != null) 'explicitList': explicitList,
      if (template != null) 'template': template!.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Children &&
        listEquals(other.explicitList, explicitList) &&
        other.template == template;
  }

  @override
  int get hashCode => Object.hash(explicitList, template);
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'componentId': componentId,
      'dataBinding': dataBinding,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Template &&
        other.componentId == componentId &&
        other.dataBinding == dataBinding;
  }

  @override
  int get hashCode => Object.hash(componentId, dataBinding);
}

class TabItem {
  const TabItem({required this.title, required this.child});

  factory TabItem.fromJson(Map<String, dynamic> json) {
    return TabItem(
      title: json['title'] as String,
      child: json['child'] as String,
    );
  }

  final String title;
  final String child;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'child': child};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TabItem && other.title == title && other.child == child;
  }

  @override
  int get hashCode => Object.hash(title, child);
}

class Action {
  const Action({required this.action, this.staticContext, this.dynamicContext});

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      action: json['action'] as String,
      staticContext: json['staticContext'] as Map<String, dynamic>?,
      dynamicContext: (json['dynamicContext'] as List<dynamic>?)
          ?.map((e) => DynamicContextItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String action;
  final Map<String, dynamic>? staticContext;
  final List<DynamicContextItem>? dynamicContext;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'action': action,
      if (staticContext != null) 'staticContext': staticContext,
      if (dynamicContext != null)
        'dynamicContext': dynamicContext!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Action &&
        other.action == action &&
        mapEquals(other.staticContext, staticContext) &&
        listEquals(other.dynamicContext, dynamicContext);
  }

  @override
  int get hashCode => Object.hash(action, staticContext, dynamicContext);
}

class DynamicContextItem {
  const DynamicContextItem({required this.key, required this.value});

  factory DynamicContextItem.fromJson(Map<String, dynamic> json) {
    return DynamicContextItem(
      key: json['key'] as String,
      value: Value.fromJson(json['value'] as Map<String, dynamic>),
    );
  }

  final String key;
  final Value value;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'key': key, 'value': value.toJson()};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DynamicContextItem &&
        other.key == key &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(key, value);
}

class Option {
  const Option({required this.label, required this.value});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      label: json['label'] as String,
      value: json['value'] as String,
    );
  }

  final String label;
  final String value;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'label': label, 'value': value};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Option && other.label == label && other.value == value;
  }

  @override
  int get hashCode => Object.hash(label, value);
}
