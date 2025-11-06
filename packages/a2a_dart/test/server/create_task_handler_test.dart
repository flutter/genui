// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:a2a_dart/src/server/a2a_server_exception.dart';
import 'package:test/test.dart';

import '../fakes.dart';

void main() {
  group('CreateTaskHandler', () {
    test('handle returns a task on success', () async {
      final task = const Task(
        id: '123',
        contextId: '456',
        status: TaskStatus(state: TaskState.submitted),
      );
      final handler = CreateTaskHandler(FakeTaskManager(taskToReturn: task));
      final params = {
        'message': {
          'messageId': '1',
          'role': 'user',
          'parts': [
            {'kind': 'text', 'text': 'Hello'},
          ],
        }
      };

      final result = await handler.handle(params);

      expect(result, isA<SingleResult>());
      expect((result as SingleResult).data['id'], equals('123'));
    });

    test('handle throws an exception if message is missing', () {
      final handler = CreateTaskHandler(FakeTaskManager(
          taskToReturn: const Task(
        id: '123',
        contextId: '456',
        status: TaskStatus(state: TaskState.submitted),
      )));
      final params = <String, dynamic>{};

      expect(
        () => handler.handle(params),
        throwsA(isA<A2AServerException>()),
      );
    });
  });
}
