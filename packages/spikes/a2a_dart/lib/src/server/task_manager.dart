import 'package:a2a_dart/src/core/task.dart';
import 'package:uuid/uuid.dart';

/// Manages the lifecycle of A2A tasks.
class TaskManager {
  final _tasks = <String, Task>{};
  final _uuid = Uuid();

  /// Creates a new task.
  Task createTask() {
    final taskId = _uuid.v4();
    final contextId = _uuid.v4();
    final task = Task(
      id: taskId,
      contextId: contextId,
      status: const TaskStatus(state: TaskState.submitted),
    );
    _tasks[taskId] = task;
    return task;
  }

  /// Retrieves a task by its ID.
  Task? getTask(String taskId) {
    return _tasks[taskId];
  }

  /// Updates a task.
  void updateTask(Task task) {
    _tasks[task.id] = task;
  }
}
