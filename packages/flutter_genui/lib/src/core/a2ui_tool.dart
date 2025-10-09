// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../model/a2ui_message.dart';
import '../model/tools.dart';
import '../primitives/simple_items.dart';

/// An [AiTool] for manipulating the UI using the A2UI protocol.
class A2UiTool extends AiTool<JsonMap> {
  /// Creates an [A2UiTool].
  A2UiTool({required this.handleMessage})
    : super(
        name: 'a2ui',
        description: 'Manipulates the UI using the A2UI protocol.',
        parameters: S.object(
          properties: {'message': S.object(description: 'An A2UI message.')},
          required: ['message'],
        ),
      );

  /// The callback to invoke when a message is received.
  final void Function(A2uiMessage message) handleMessage;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final message = A2uiMessage.fromJson(args['message'] as JsonMap);
    handleMessage(message);
    return {'status': 'ok'};
  }
}
