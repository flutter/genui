// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:test/test.dart';

import '../fakes.dart';

void main() {
  group('ResubscribeHandler', () {
    late TaskManager taskManager;
    late ResubscribeHandler handler;

    test('returns a stream when it exists', () async {
      final task = const Task(
        id: 'task-1',
        contextId: 'context-1',
        status: TaskStatus(state: TaskState.working),
      );
      taskManager = FakeTaskManager(
        taskToReturn: task,
        stream: Stream.value({}),
      );
      await (taskManager as FakeTaskManager).ensureTaskExists(task);
      handler = ResubscribeHandler(taskManager);

      final result = await handler.handle({'id': task.id});
      expect(result, isA<StreamResult>());
    });

    test('throws an exception when stream does not exist', () {
      final taskManager = FakeTaskManager();
      final handler = ResubscribeHandler(taskManager);
      expect(
        () => handler.handle({'id': 'non-existent-task'}),
        throwsA(isA<A2AServerException>()),
      );
    });

    test('throws an exception when id is missing', () {
      final task = const Task(
        id: 'task-1',
        contextId: 'context-1',
        status: TaskStatus(state: TaskState.working),
      );
      taskManager = FakeTaskManager(taskToReturn: task);
      handler = ResubscribeHandler(taskManager);

      expect(() => handler.handle({}), throwsA(isA<A2AServerException>()));
    });
  });
}
