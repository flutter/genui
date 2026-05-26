// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

/// A class for handling JSON Pointer-style paths.
///
/// Splits paths on `/` only; does not implement RFC 6901 `~0`/`~1`
/// escaping for `~`/`/` within segments. This matches the web_core
/// reference implementation, despite the v0.9 spec citing RFC 6901.
class DataPath {
  final List<String> segments;

  DataPath(this.segments);

  /// Parses a JSON Pointer string into a [DataPath].
  factory DataPath.parse(String path) {
    if (path.isEmpty || path == '/') {
      return DataPath([]);
    }

    var normalized = path;
    if (path.startsWith('/')) {
      normalized = path.substring(1);
    }

    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    if (normalized.isEmpty) {
      return DataPath([]);
    }

    final List<String> segments = normalized.split('/');

    return DataPath(segments);
  }

  /// The number of segments in the path.
  int get length => segments.length;

  /// Whether the path is empty (points to the root).
  bool get isEmpty => segments.isEmpty;

  /// Whether the path starts with a slash (is absolute).
  bool get isAbsolute =>
      true; // All parsed paths are treated as absolute for now in our context

  /// Joins this path with another path or segment.
  DataPath append(Object? other) {
    if (other is DataPath) {
      return DataPath([...segments, ...other.segments]);
    } else if (other is String) {
      if (other.startsWith('/')) {
        return DataPath.parse(other);
      }
      return DataPath([...segments, ...DataPath.parse(other).segments]);
    }
    return DataPath([...segments, other.toString()]);
  }

  /// Returns the parent path.
  DataPath? get parent {
    if (segments.isEmpty) return null;
    return DataPath(segments.sublist(0, segments.length - 1));
  }

  @override
  String toString() {
    if (segments.isEmpty) return '/';
    return '/${segments.join('/')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPath &&
          const ListEquality<String>().equals(segments, other.segments);

  @override
  int get hashCode => const ListEquality<String>().hash(segments);
}
