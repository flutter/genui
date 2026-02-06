// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Categories of finish status of a response from model or agent.
enum FinishCategory {
  /// The response is not finished.
  notFinished,

  /// The response is finished as completed.
  completed,

  /// The response is finished as result of interruption.
  interrupted,
}

class _Json {
  static const category = 'category';
  static const details = 'details';
}

@immutable
class FinishStatus {
  final FinishCategory category;

  /// Optional details about the finish status.
  final String? details;

  const FinishStatus({required this.category, this.details});

  const FinishStatus.notFinished() : this(category: FinishCategory.notFinished);

  const FinishStatus.completed() : this(category: FinishCategory.completed);

  const FinishStatus.interrupted({String? details})
    : this(category: FinishCategory.interrupted, details: details);

  /// Deserializes a [FinishStatus].
  factory FinishStatus.fromJson(Map<String, Object?> json) {
    return FinishStatus(
      category: FinishCategory.values.byName(json[_Json.category] as String),
      details: json[_Json.details] as String?,
    );
  }

  /// Serializes the [FinishStatus] to JSON.
  Map<String, Object?> toJson() => {
    _Json.category: category.name,
    if (details != null) _Json.details: details,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinishStatus &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          details == other.details;

  @override
  int get hashCode => Object.hash(category, details);

  @override
  String toString() => 'FinishStatus(category: $category, details: $details)';
}
