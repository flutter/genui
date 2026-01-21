// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../model.dart';

final class _Json {
  static const content = 'content';
}

/// A text part of a message.
@immutable
final class TextPart extends Part {
  static const type = 'Text';

  /// Creates a new text part.
  const TextPart(this.text);

  /// The text content.
  final String text;

  /// Creates a text part from a JSON-compatible map.
  factory TextPart.fromJson(Map<String, Object?> json) {
    return TextPart(json[_Json.content] as String);
  }

  @override
  Map<String, Object?> toJson() => {Part.typeKey: type, _Json.content: text};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is TextPart && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextPart($text)';
}
