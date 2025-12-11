// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../core/ui_tools.dart';
import '../../primitives/simple_items.dart';
import '../a2ui_message.dart';
import '../a2ui_protocol.dart';
import '../catalog.dart';
import '../tools.dart';

/// Implementation of the A2UI protocol for version 0.8.
class A2uiProtocolV08 implements A2uiProtocol {
  /// Creates an instance of [A2uiProtocolV08].
  const A2uiProtocolV08();

  @override
  A2uiProtocolVersion get version => A2uiProtocolVersion.v0_8;

  @override
  Stream<A2uiMessage> parsePayload(Object payload) {
    if (payload is JsonMap) {
      // Direct JSON map (single message)
      try {
        return Stream.value(parseJson(payload));
      } on FormatException {
        // This is likely not an A2UI message (e.g. a tool output), so we
        // can safely ignore it, maintaining backward compatibility with the
        // lenient parsing behavior.
        return const Stream.empty();
      } catch (e, s) {
        // Any other exception is a potential issue with a message that was
        // intended to be a valid A2UI message and should be reported.
        return Stream.error(e, s);
      }
    }
    // If we handle lines (String) or other formats, logic goes here.
    return const Stream.empty();
  }

  /// Parses a single JSON map into an [A2uiMessage].
  @override
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
    throw FormatException('Unknown A2UI message type: $json');
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
