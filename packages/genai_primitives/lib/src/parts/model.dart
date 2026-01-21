// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../parts/parts.dart';
library;

import 'dart:convert';

import 'package:meta/meta.dart';

/// Base class for message content parts.
///
/// To create a custom part implementation, extend this class and ensure the
/// following requirements are met for a robust implementation:
///
/// * **Equality and Hashing**: Override [operator ==] and [hashCode] to
///   ensure value-based equality.
/// * **Serialization**: Implement a `toJson()` method that returns a
///   JSON-encodable [Map]. The map must contain a `type` field with a unique
///   string identifier for the custom part. See [defaultPartConverterRegistry]
///   for the default registry and existing part types.
/// * **Deserialization**: Implement a `JsonToPartConverter` that can recreate
///   the part from its JSON representation.
/// * Pass extended [defaultPartConverterRegistry] to all methods `fromJson`
///   that accept a converter registry.
@immutable
abstract base class Part {
  /// Creates a new part.
  const Part();

  /// The key of the part type in the JSON representation.
  static const String typeKey = 'type';

  /// Deserializes a part from a JSON map.
  ///
  /// The [converterRegistry] parameter is a map of part types to converters.
  factory Part.fromJson(
    Map<String, Object?> json, {
    required Map<String, JsonToPartConverter> converterRegistry,
  }) {
    final type = json[typeKey] as String;
    final JsonToPartConverter? converter = converterRegistry[type];
    if (converter == null) {
      throw UnimplementedError('Unknown part type: $type');
    }
    return converter.convert(json);
  }

  /// Serializes the part to a JSON map.
  ///
  /// The returned map must contain a key matching [typeKey] with a unique
  /// string identifier for the part type. See [defaultPartConverterRegistry]
  /// for default part types.
  Map<String, Object?> toJson();
}

typedef JsonToPartConverter = Converter<Map<String, Object?>, Part>;
