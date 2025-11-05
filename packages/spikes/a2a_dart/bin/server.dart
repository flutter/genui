import 'package:a2a_dart/src/server/a2a_server.dart';
import 'package:a2a_dart/src/server/create_task_handler.dart';
import 'package:a2a_dart/src/server/task_manager.dart';

Future<void> main(List<String> arguments) async {
  final taskManager = TaskManager();
  final server = A2AServer([CreateTaskHandler(taskManager)]);

  await server.start();
}
