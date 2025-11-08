// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../core/message.dart';
import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles JSON-RPC requests for the `create_task` method.
///
/// This handler is responsible for initiating a new task based on the provided
/// [Message]. It uses the [TaskManager] to create and store the new task.
class CreateTaskHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [CreateTaskHandler].
  ///
  /// Requires a [TaskManager] instance to manage task creation and storage.
  CreateTaskHandler(this._taskManager);

  @override
  String get method => 'create_task';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  FutureOr<HandlerResult> handle(Map<String, Object?> params) async {
    if (!params.containsKey('message')) {
      throw A2AServerException(
        'Missing required parameter: message',
        -32602, // Invalid params
      );
    }
    try {
      final message = Message.fromJson(
        params['message'] as Map<String, Object?>,
      );
      final task = await _taskManager.createTask(message);
      return SingleResult(task.toJson());
    } on FormatException catch (e) {
      throw A2AServerException(
        'Invalid message format: $e',
        -32602, // Invalid params
      );
    }
  }
}
