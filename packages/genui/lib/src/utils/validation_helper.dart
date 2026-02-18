// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:rxdart/rxdart.dart';

import '../functions/expression_parser.dart';
import '../primitives/simple_items.dart';

/// A helper class for handling reactive validation logic.
class ValidationHelper {
  /// Validates a value against a list of checks.
  ///
  /// Returns a [Stream] that emits an error message if any check fails, or null
  /// if all checks pass.
  ///
  /// The [checks] list should contain maps with 'condition' and optional
  /// 'message' keys. The [parser] is used to evaluate the conditions.
  static Stream<String?> validateStream(
    List<JsonMap>? checks,
    ExpressionParser? parser,
  ) {
    if (checks == null || checks.isEmpty || parser == null) {
      return Stream.value(null);
    }

    final List<Stream<(bool, String)>> streams = [];
    for (final JsonMap check in checks) {
      final String message = check['message'] as String? ?? 'Invalid value';
      streams.add(
        parser
            .evaluateConditionStream(check['condition'])
            .map((isValid) => (isValid, message)),
      );
    }

    return CombineLatestStream.list(streams).map((results) {
      for (final (isValid, msg) in results) {
        if (!isValid) return msg;
      }
      return null;
    });
  }
}
