// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A strategy for cleaning up surfaces.
abstract interface class SurfaceCleanupStrategy {
  /// Determines which surfaces should be removed.
  ///
  /// [surfaceOrder] is the list of surfaces in creation/update order (oldest first).
  /// Returns a list of surface IDs to remove.
  List<String> cleanup(List<String> surfaceOrder);
}

/// A manual cleanup strategy that does nothing.
class ManualCleanupStrategy implements SurfaceCleanupStrategy {
  const ManualCleanupStrategy();

  @override
  List<String> cleanup(List<String> surfaceOrder) => const [];
}

/// A cleanup strategy that keeps the latest N surfaces.
class KeepLastNCleanupStrategy implements SurfaceCleanupStrategy {
  const KeepLastNCleanupStrategy(this.n);

  final int n;

  @override
  List<String> cleanup(List<String> surfaceOrder) {
    if (surfaceOrder.length > n) {
      return surfaceOrder.sublist(0, surfaceOrder.length - n);
    }
    return const [];
  }
}
