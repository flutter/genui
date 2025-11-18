// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ListTasksHandler', () {
    late TaskManager taskManager;
    late ListTasksHandler handler;

    setUp(() {
      taskManager = InMemoryTaskManager();
      handler = ListTasksHandler(taskManager);
    });

    test('returns a list of tasks', () async {
      await taskManager.createTask();
      await taskManager.createTask();

      final result = await handler.handle({});
      expect(result, isA<SingleResult>());

      final data = (result as SingleResult).data;
      final listResult = ListTasksResult.fromJson(data);
      expect(listResult.tasks, hasLength(2));
      expect(listResult.totalSize, equals(2));
    });
  });
}
