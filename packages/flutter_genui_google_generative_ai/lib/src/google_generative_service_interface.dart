// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;

/// An interface for a generative service, allowing for mock implementations.
///
/// This interface abstracts the underlying generative service, allowing for
/// different implementations to be used, for example, in testing.
abstract class GoogleGenerativeServiceInterface {
  /// Generates content from the given [request].
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  );

  /// Closes the service and releases any resources.
  void close();
}

/// A wrapper for the `google_cloud_ai_generativelanguage_v1beta`
/// [google_ai.GenerativeService] that implements the
/// [GoogleGenerativeServiceInterface].
///
/// This class is used to wrap the Google Cloud AI [google_ai.GenerativeService]
/// so that it can be used interchangeably with other implementations of the
/// [GoogleGenerativeServiceInterface].
class GoogleGenerativeServiceWrapper
    implements GoogleGenerativeServiceInterface {
  /// Creates a new [GoogleGenerativeServiceWrapper] that wraps the given
  /// [_service].
  GoogleGenerativeServiceWrapper(this._service);

  final google_ai.GenerativeService _service;

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) {
    return _service.generateContent(request);
  }

  @override
  void close() {
    _service.close();
  }
}
