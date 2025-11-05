import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../core/message.dart';
import 'request_handler.dart';
import 'task_manager.dart';

class CreateTaskHandler implements RequestHandler {
  final TaskManager _taskManager;

  CreateTaskHandler(this._taskManager);

  @override
  String get method => 'create_task';

  @override
  FutureOr<Response> handle(Request request) async {
    final body = await request.readAsString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final params = json['params'] as Map<String, dynamic>;
    // The message is not used yet, but it will be needed in the future.
    // ignore: unused_local_variable
    final message = Message.fromJson(params['message'] as Map<String, dynamic>);

    final task = _taskManager.createTask();

    final response = {
      'jsonrpc': '2.0',
      'result': task.toJson(),
      'id': json['id'],
    };

    return Response.ok(
      jsonEncode(response),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
