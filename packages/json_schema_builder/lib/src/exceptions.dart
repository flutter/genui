// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class SchemaFetchException implements Exception {
  final Uri uri;
  final Object? cause;

  SchemaFetchException(this.uri, [this.cause]);

  @override
  String toString() {
    var message = 'Error fetching remote schema from $uri';
    if (cause != null) {
      message = '$message: $cause';
    }
    return message;
  }
}

/// Thrown by the synchronous validation path when a reference can only be
/// resolved by fetching a schema that is not in the `SchemaRegistry` yet.
///
/// Synchronous validation never performs I/O, so it cannot fetch the schema
/// itself. Rather than treating the unresolved subschema as unconstrained,
/// which would silently turn a missing fetch into a passing validation, it
/// throws this exception.
///
/// To fix it, either bring the schema at [uri] into the registry before
/// validating (with `SchemaRegistry.addSchema` or
/// `SchemaRegistry.prefetchDependencies`), or use the asynchronous `validate`
/// method, which fetches the remote schemas it needs before validating.
class SchemaResolutionRequiredException implements Exception {
  /// The URI of the schema that would have to be fetched, without any fragment.
  final Uri uri;

  SchemaResolutionRequiredException(this.uri);

  @override
  String toString() =>
      'Synchronous validation requires the schema at $uri, which is not '
      'registered. Add it to the SchemaRegistry, or use the asynchronous '
      'Schema.validate to fetch it.';
}
