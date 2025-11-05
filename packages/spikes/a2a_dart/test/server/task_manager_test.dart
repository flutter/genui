import 'package:a2a_dart/src/core/task.dart';
import 'package:a2a_dart/src/server/task_manager.dart';
import 'package:test/test.dart';

void main() {
  group('TaskManager', () {
    test('createTask creates a new task with a unique ID', () {
      final taskManager = TaskManager();
      final task1 = taskManager.createTask();
      final task2 = taskManager.createTask();

      expect(task1.id, isNot(equals(task2.id)));
      expect(task1.status.state, equals(TaskState.submitted));
    });

    test('getTask retrieves a task by its ID', () {
      final taskManager = TaskManager();
      final task = taskManager.createTask();
      final retrievedTask = taskManager.getTask(task.id);

      expect(retrievedTask, isNotNull);
      expect(retrievedTask!.id, equals(task.id));
    });

    test('updateTask updates a task', () {
      final taskManager = TaskManager();
      final task = taskManager.createTask();
      final updatedTask = task.copyWith(
        status: const TaskStatus(state: TaskState.working),
      );

      taskManager.updateTask(updatedTask);

      final retrievedTask = taskManager.getTask(task.id);

      expect(retrievedTask, isNotNull);
      expect(retrievedTask!.status.state, equals(TaskState.working));
    });
  });
}
