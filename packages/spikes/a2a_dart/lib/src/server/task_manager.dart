import 'package:a2a_dart/src/core/task.dart';
import 'package:uuid/uuid.dart';

/// Manages the lifecycle of A2A tasks in memory.
///
/// This class is responsible for creating, retrieving, and updating tasks. It
/// uses a [Map] to store tasks, with the task ID as the key.
class TaskManager {
  final _tasks = <String, Task>{};
  final _uuid = Uuid();

  /// Creates a new [Task] with a unique ID and `submitted` status.
  ///
  /// The new task is stored in the task manager and then returned.
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
  ///
  /// Returns the [Task] if it exists, otherwise returns `null`.
  Task? getTask(String taskId) {
    return _tasks[taskId];
  }

  /// Updates the state of an existing task.
  ///
  /// If a task with the same ID already exists, it will be overwritten.
  void updateTask(Task task) {
    _tasks[task.id] = task;
  }
}
