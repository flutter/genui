// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:stream_transform/stream_transform.dart';

/// Extensions for [Iterable] of [Stream]s.
extension CombineLatestAll<T> on Iterable<Stream<T>> {
  /// Combines all streams in this iterable into a single stream that emits a
  /// list of the latest values from each stream.
  ///
  /// The resulting stream will not emit until every stream in the iterable has
  /// emitted at least one value.
  Stream<List<T>> combineLatestAll() {
    if (isEmpty) return Stream.value([]);

    return first.combineLatestAll(skip(1));
  }
}
