// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../primitives/simple_items.dart' show JsonMap;
import 'a2ui_message.dart';
import 'catalog.dart';
import 'tools.dart';
import 'v0_8/a2ui_protocol_v0_8.dart';

/// The versions of the A2UI protocol.
enum A2uiProtocolVersion {
  /// Version 0.8.
  v0_8,

  /// Version 0.9. (not yet implemented)
  v0_9;

  /// Returns the string representation of the version (e.g. "0.8").
  String get label => switch (this) {
    A2uiProtocolVersion.v0_8 => '0.8',
    A2uiProtocolVersion.v0_9 => '0.9',
  };
}

/// An abstract interface for the A2UI protocol.
///
/// This allows for supporting multiple versions of the A2UI spec (e.g. 0.8,
/// 0.9) and potentially non-JSON protocols in the future.
abstract interface class A2uiProtocol {
  /// Creates an instance of [A2uiProtocol] from an [A2uiProtocolVersion].
  factory A2uiProtocol.fromVersion(A2uiProtocolVersion version) {
    switch (version) {
      case A2uiProtocolVersion.v0_8:
        return const A2uiProtocolV08();
      case A2uiProtocolVersion.v0_9:
        throw UnimplementedError(
          'A2uiProtocol version ${version.label} is not yet supported.',
        );
    }
  }

  /// The version of the A2UI protocol.
  A2uiProtocolVersion get version;

  /// Parses the payload into a stream of [A2uiMessage]s.
  ///
  /// The [payload] can be a JSON Map, a String (for text-based protocols or
  /// scripts), or other formats.
  Stream<A2uiMessage> parsePayload(Object payload);

  /// Parses a single JSON map into an [A2uiMessage].
  ///
  /// This is synchronous and expects a well-formed JSON object representing a
  /// single message.
  A2uiMessage parseJson(JsonMap json);

  /// Returns the tools required by this protocol version for inference.
  ///
  /// For 0.8, this returns tools like `surfaceUpdate` that the LLM calls.
  /// For prompt-first protocols (like 0.9), this might return an empty list or
  /// only auxiliary tools.
  List<AiTool> getTools(Catalog catalog, void Function(A2uiMessage) onMessage);

  /// Returns the system preamble (instructions/schema) for this protocol.
  ///
  /// For prompt-first protocols, this provides the instructions that tell the
  /// LLM how to generate the UI (e.g. the JSON schema in text form).
  /// For tool-use protocols (0.8), this might be null or minimal.
  String? get systemPreamble;
}
