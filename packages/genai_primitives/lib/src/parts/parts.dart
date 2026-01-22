// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'model.dart';
import 'standard_part.dart';

/// A collection of parts.
@immutable
final class Parts extends ListBase<Part> {
  /// Creates a new collection of parts.
  const Parts(this._parts);

  /// Creates a collection of parts from text and optional other parts.
  ///
  /// If [text] is not empty, converts it to a [TextPart] and puts it as a
  /// first member of the [parts] list.
  factory Parts.fromText(String text, {Iterable<Part> parts = const []}) =>
      text.isEmpty ? Parts(parts.toList()) : Parts([TextPart(text), ...parts]);

  /// Deserializes parts from a JSON list.
  factory Parts.fromJson(
    List<Object?> json, {
    Map<String, JsonToPartConverter> converterRegistry =
        defaultPartConverterRegistry,
  }) {
    return Parts(
      json
          .map(
            (e) => Part.fromJson(
              e as Map<String, Object?>,
              converterRegistry: converterRegistry,
            ),
          )
          .toList(),
    );
  }

  final List<Part> _parts;

  @override
  int get length => _parts.length;

  @override
  set length(int newLength) => throw UnsupportedError('Parts is immutable');

  @override
  Part operator [](int index) => _parts[index];

  @override
  void operator []=(int index, Part value) =>
      throw UnsupportedError('Parts is immutable');

  /// Serializes parts to a JSON list.
  List<Object?> toJson() => _parts.map((p) => p.toJson()).toList();

  /// Extracts and concatenates all text content from TextPart instances.
  ///
  /// Returns a single string with all text content concatenated together
  /// without any separators. Empty text parts are included in the result.
  String get text => whereType<TextPart>().map((p) => p.text).join();

  /// Extracts all tool call parts from the list.
  ///
  /// Returns only ToolPart instances where kind == ToolPartKind.call.
  List<ToolPart> get toolCalls =>
      whereType<ToolPart>().where((p) => p.kind == ToolPartKind.call).toList();

  /// Extracts all tool result parts from the list.
  ///
  /// Returns only ToolPart instances where kind == ToolPartKind.result.
  List<ToolPart> get toolResults => whereType<ToolPart>()
      .where((p) => p.kind == ToolPartKind.result)
      .toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    const deepEquality = DeepCollectionEquality();
    return other is Parts && deepEquality.equals(other._parts, _parts);
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(_parts);

  @override
  String toString() => _parts.toString();
}
