// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../model.dart';

final class _Json {
  static const content = 'content';
  static const mimeType = 'mimeType';
  static const name = 'name';
  static const url = 'url';
}

/// A link part referencing external content.
@immutable
final class LinkPart extends Part {
  static const type = 'Link';

  /// Creates a new link part.
  const LinkPart(this.url, {this.mimeType, this.name});

  /// The URL of the external content.
  final Uri url;

  /// Optional MIME type of the linked content.
  final String? mimeType;

  /// Optional name for the link.
  final String? name;

  /// Creates a link part from a JSON-compatible map.
  factory LinkPart.fromJson(Map<String, Object?> json) {
    final content = json[_Json.content] as Map<String, Object?>;
    return LinkPart(
      Uri.parse(content[_Json.url] as String),
      mimeType: content[_Json.mimeType] as String?,
      name: content[_Json.name] as String?,
    );
  }

  @override
  Map<String, Object?> toJson() => {
    Part.typeKey: type,
    _Json.content: {
      if (name != null) _Json.name: name,
      if (mimeType != null) _Json.mimeType: mimeType,
      _Json.url: url.toString(),
    },
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is LinkPart &&
        other.url == url &&
        other.mimeType == mimeType &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(url, mimeType, name);

  @override
  String toString() => 'LinkPart(url: $url, mimeType: $mimeType, name: $name)';
}
