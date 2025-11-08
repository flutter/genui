// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../core/push_notification.dart';
import 'a2a_server_exception.dart';
import 'handler_result.dart';
import 'request_handler.dart';
import 'task_manager.dart';

/// Handles JSON-RPC requests for the `tasks/pushNotificationConfig/set` method.
///
/// This handler creates or updates a push notification configuration for a
/// specific task using the [TaskManager].
class SetPushConfigHandler implements RequestHandler {
  final TaskManager _taskManager;

  /// Creates a [SetPushConfigHandler].
  ///
  /// Requires a [TaskManager] instance to manage push configurations.
  SetPushConfigHandler(this._taskManager);

  @override
  String get method => 'tasks/pushNotificationConfig/set';

  @override
  List<Map<String, List<String>>>? get securityRequirements => null;

  @override
  Future<HandlerResult> handle(Map<String, Object?> params) async {
    try {
      final taskPushConfig = TaskPushNotificationConfig.fromJson(params);
      final taskId = taskPushConfig.taskId;
      final config = taskPushConfig.pushNotificationConfig;

      final task = await _taskManager.getTask(taskId);
      if (task == null) {
        throw A2AServerException(
          'Task not found: $taskId',
          -32001, // Custom: Task not found
        );
      }

      await _taskManager.setPushNotificationConfig(taskId, config);
      // The spec says to return the config, but the TaskPushNotificationConfig
      // is the request object, so we return that.
      return SingleResult(taskPushConfig.toJson());
    } on FormatException catch (e) {
      throw A2AServerException(
        'Invalid parameters for tasks/pushNotificationConfig/set: $e',
        -32602, // Invalid params
      );
    }
  }
}
