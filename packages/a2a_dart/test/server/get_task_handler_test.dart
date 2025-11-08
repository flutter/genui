// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GetTaskHandler', () {
    late TaskManager taskManager;
    late GetTaskHandler handler;

    setUp(() {
      taskManager = InMemoryTaskManager();
      handler = GetTaskHandler(taskManager);
    });

    test('returns a task when it exists', () async {
      final task = await taskManager.createTask();
      final handler = GetTaskHandler(taskManager);
      final result = await handler.handle({'id': task.id}) as SingleResult;
      final data = result.data;
      expect(data['id'], equals(task.id));
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
