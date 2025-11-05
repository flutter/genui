import 'dart:async';

import '../core/message.dart';
import 'request_handler.dart';
import 'task_manager.dart';

class CreateTaskHandler implements RequestHandler {
  final TaskManager _taskManager;

  CreateTaskHandler(this._taskManager);

  @override
  String get method => 'create_task';

  @override
  FutureOr<Map<String, dynamic>> handle(Map<String, dynamic> params) {
    // The message is not used yet, but it will be needed in the future.
    // ignore: unused_local_variable
    final message = Message.fromJson(params['message'] as Map<String, dynamic>);

    final task = _taskManager.createTask();

    return task.toJson();
  }
}
