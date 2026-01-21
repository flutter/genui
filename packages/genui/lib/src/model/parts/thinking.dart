// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:genai_primitives/genai_primitives.dart';

/// A provider-specific part for "thinking" blocks.
final class ThinkingPart extends Part {
  static const String type = 'thinking';

  /// The reasoning content from the model.
  final String text;

  /// Creates a [ThinkingPart] with the given [text].
  const ThinkingPart(this.text);

  /// Creates a [ThinkingPart] from a JSON map.
  factory ThinkingPart.fromJson(Map<String, Object?> json) {
    return ThinkingPart(json['text'] as String);
  }

  @override
  Map<String, Object?> toJson() => {Part.typeKey: type, 'text': text};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThinkingPart && other.text == text;
  }

  @override
  int get hashCode => Object.hash(type, text);
}
