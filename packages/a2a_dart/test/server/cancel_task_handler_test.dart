// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CancelTaskHandler', () {
    late TaskManager taskManager;
    late CancelTaskHandler handler;

    setUp(() {
      taskManager = InMemoryTaskManager();
      handler = CancelTaskHandler(taskManager);
    });

    test('cancels a task when it exists', () async {
      final task = await taskManager.createTask();
      final result = await handler.handle({'id': task.id});
      expect(result, isA<SingleResult>());
      final data = (result as SingleResult).data;
      final canceledTask = Task.fromJson(data);
      expect(canceledTask.status.state, equals(TaskState.canceled));
      expect(data, equals(canceledTask.toJson()));
    });

    test('throws an exception when task does not exist', () {
      expect(
        () => handler.handle({'id': 'non-existent-task'}),
        throwsA(isA<A2AServerException>()),
      );
    });

    test('throws an exception when id is missing', () {
      expect(() => handler.handle({}), throwsA(isA<A2AServerException>()));
    });
  });
}
