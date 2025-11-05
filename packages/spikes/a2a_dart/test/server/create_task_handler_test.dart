import 'dart:convert';

import 'package:a2a_dart/src/core/task.dart';
import 'package:a2a_dart/src/server/create_task_handler.dart';
import 'package:a2a_dart/src/server/task_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'create_task_handler_test.mocks.dart';

@GenerateMocks([TaskManager])
void main() {
  group('CreateTaskHandler', () {
    test('handle returns a task on success', () async {
      final taskManager = MockTaskManager();
      final handler = CreateTaskHandler(taskManager);
      final request = Request(
        'POST',
        Uri.parse('http://localhost/rpc'),
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'create_task',
          'params': {
            'message': {
              'messageId': '1',
              'role': 'user',
              'parts': [
                {'kind': 'text', 'text': 'Hello'}
              ]
            }
          },
          'id': 1,
        }),
      );
      final task = Task(
        id: '123',
        contextId: '456',
        status: const TaskStatus(state: TaskState.submitted),
      );

      when(taskManager.createTask()).thenReturn(task);

      final response = await handler.handle(request);

      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['result']['id'], equals('123'));
    });
  });
}
