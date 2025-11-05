import 'package:a2a_dart/src/core/task.dart';
import 'package:a2a_dart/src/server/create_task_handler.dart';
import 'package:a2a_dart/src/server/task_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'create_task_handler_test.mocks.dart';

@GenerateMocks([TaskManager])
void main() {
  group('CreateTaskHandler', () {
    test('handle returns a task on success', () async {
      final taskManager = MockTaskManager();
      final handler = CreateTaskHandler(taskManager);
      final params = {
        'message': {
          'messageId': '1',
          'role': 'user',
          'parts': [
            {'kind': 'text', 'text': 'Hello'},
          ],
        }
      };
      final task = Task(
        id: '123',
        contextId: '456',
        status: const TaskStatus(state: TaskState.submitted),
      );

      when(taskManager.createTask()).thenReturn(task);

      final result = await handler.handle(params);

      expect(result['id'], equals('123'));
    });
  });
}
