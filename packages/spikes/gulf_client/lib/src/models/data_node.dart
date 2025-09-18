// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

class DataModelNode {
  const DataModelNode({
    required this.id,
    this.value,
    this.children,
    this.items,
  });

  factory DataModelNode.fromJson(Map<String, dynamic> json) {
    return DataModelNode(
      id: json['id'] as String,
      value: json['value'],
      children: (json['children'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as String),
      ),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  final String id;
  final dynamic value;
  final Map<String, String>? children;
  final List<String>? items;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (value != null) 'value': value,
      if (children != null) 'children': children,
      if (items != null) 'items': items,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DataModelNode &&
        other.id == id &&
        other.value == value &&
        mapEquals(other.children, children) &&
        listEquals(other.items, items);
  }

  @override
  int get hashCode {
    return Object.hash(id, value, children, items);
  }
}
