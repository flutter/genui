// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TaskManager', () {
    test('createTask creates a new task with a unique ID', () async {
      final taskManager = InMemoryTaskManager();
      final task1 = await taskManager.createTask();
      final task2 = await taskManager.createTask();

      expect(task1.id, isNot(equals(task2.id)));
      expect(task1.status.state, equals(TaskState.submitted));
    });

    test('getTask retrieves a task by its ID', () async {
      final taskManager = InMemoryTaskManager();
      final task = await taskManager.createTask();
      final retrievedTask = await taskManager.getTask(task.id);

      expect(retrievedTask, isNotNull);
      expect(retrievedTask!.id, equals(task.id));
    });

    test('updateTask updates a task', () async {
      final taskManager = InMemoryTaskManager();
      final task = await taskManager.createTask();
      final updatedTask = task.copyWith(
        status: const TaskStatus(state: TaskState.working),
      );

      await taskManager.updateTask(updatedTask);

      final retrievedTask = await taskManager.getTask(task.id);

      expect(retrievedTask, isNotNull);
      expect(retrievedTask!.status.state, equals(TaskState.working));
    });

    test('getTask returns null if task is not found', () async {
      final taskManager = InMemoryTaskManager();
      final retrievedTask = await taskManager.getTask('non-existent-id');

      expect(retrievedTask, isNull);
    });
  });
}
