// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A class that represents a request to the AI.
class RequestContext {
  /// Creates a new [RequestContext].
  RequestContext({
    required this.requestId,
    this.surfaceId,
    this.widgetId,
    required this.requestTime,
  });

  /// A unique ID for the request.
  final String requestId;

  /// The surface that initiated the request (if any).
  final String? surfaceId;

  /// The widget that initiated the request (if any).
  final String? widgetId;

  /// The time the request was made.
  final DateTime requestTime;
}
