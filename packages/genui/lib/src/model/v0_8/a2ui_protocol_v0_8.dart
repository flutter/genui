// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: camel_case_types

import 'dart:async';

import '../../core/ui_tools.dart';
import '../../primitives/simple_items.dart';
import '../a2ui_message.dart';
import '../a2ui_protocol.dart';
import '../catalog.dart';
import '../tools.dart';

/// Implementation of the A2UI protocol for version 0.8.
class A2uiProtocolV0_8 implements A2uiProtocol {
  /// Creates an instance of [A2uiProtocolV0_8].
  const A2uiProtocolV0_8();

  @override
  A2uiProtocolVersion get version => A2uiProtocolVersion.v0_8;

  @override
  Stream<A2uiMessage> parsePayload(Object payload) {
    if (payload is JsonMap) {
      // Direct JSON map (single message)
      try {
        return Stream.value(parseJson(payload));
      } catch (e) {
        // If it's not a valid 0.8 message, return empty or error.
        // For backwards compatibility with the lenient parser, we'll return
        // empty if keys are missing from the dispatch check in parseJson,
        // but parseJson throws ArgumentError if keys are unknown.
        // However, parsePayload might receive partial data or tool outputs that
        // are not A2UI messages.
        return const Stream.empty();
      }
    }
    // If we handle lines (String) or other formats, logic goes here.
    return const Stream.empty();
  }

  /// Parses a single JSON map into an [A2uiMessage].
  A2uiMessage parseJson(JsonMap json) {
    if (json.containsKey('surfaceUpdate')) {
      return SurfaceUpdate.fromJson(json['surfaceUpdate'] as JsonMap);
    }
    if (json.containsKey('dataModelUpdate')) {
      return DataModelUpdate.fromJson(json['dataModelUpdate'] as JsonMap);
    }
    if (json.containsKey('beginRendering')) {
      return BeginRendering.fromJson(json['beginRendering'] as JsonMap);
    }
    if (json.containsKey('deleteSurface')) {
      return SurfaceDeletion.fromJson(json['deleteSurface'] as JsonMap);
    }
    throw ArgumentError('Unknown A2UI message type: $json');
  }

  @override
  List<AiTool> getTools(Catalog catalog, void Function(A2uiMessage) onMessage) {
    return [
      SurfaceUpdateTool(handleMessage: onMessage, catalog: catalog),
      BeginRenderingTool(
        handleMessage: onMessage,
        catalogId: catalog.catalogId,
      ),
      DeleteSurfaceTool(handleMessage: onMessage),
    ];
  }

  @override
  String? get systemPreamble => null;
}
