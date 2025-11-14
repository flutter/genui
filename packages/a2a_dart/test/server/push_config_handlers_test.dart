// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:a2a_dart/src/core/push_notification.dart';
import 'package:a2a_dart/src/server/delete_push_config_handler.dart';
import 'package:a2a_dart/src/server/get_push_config_handler.dart';
import 'package:a2a_dart/src/server/list_push_configs_handler.dart';
import 'package:a2a_dart/src/server/set_push_config_handler.dart';
import 'package:test/test.dart';

import '../fakes.dart';

void main() {
  group('Push Config Handlers', () {
    late FakeTaskManager fakeTaskManager;
    late SetPushConfigHandler setHandler;
    late GetPushConfigHandler getHandler;
    late ListPushConfigsHandler listHandler;
    late DeletePushConfigHandler deleteHandler;

    const taskId = 'test-task-id';
    const configId = 'test-config-id';
    final pushConfig = const PushNotificationConfig(
      id: configId,
      url: 'https://example.com/push',
    );
    final taskPushConfig = TaskPushNotificationConfig(
      taskId: taskId,
      pushNotificationConfig: pushConfig,
    );
    final testTask = const Task(
      id: taskId,
      contextId: 'test-context',
      status: TaskStatus(state: TaskState.working),
    );

    setUp(() {
      fakeTaskManager = FakeTaskManager(taskToReturn: testTask);
      setHandler = SetPushConfigHandler(fakeTaskManager);
      getHandler = GetPushConfigHandler(fakeTaskManager);
      listHandler = ListPushConfigsHandler(fakeTaskManager);
      deleteHandler = DeletePushConfigHandler(fakeTaskManager);
      fakeTaskManager.ensureTaskExists(testTask);
    });

    group('SetPushConfigHandler', () {
      test('should set push config successfully', () async {
        final result = await setHandler.handle(taskPushConfig.toJson());

        expect(result, isA<SingleResult>());
        expect((result as SingleResult).data, equals(taskPushConfig.toJson()));
        expect(
          await fakeTaskManager.getPushNotificationConfig(taskId, configId),
          equals(pushConfig),
        );
      });

      test('should throw if task not found', () async {
        fakeTaskManager.taskToReturn = null;
        expect(
          () => setHandler.handle(taskPushConfig.toJson()),
          throwsA(
            isA<A2AServerException>().having((e) => e.code, 'code', -32001),
          ),
        );
      });
    });

    group('GetPushConfigHandler', () {
      test('should get push config successfully', () async {
        await fakeTaskManager.setPushNotificationConfig(taskId, pushConfig);

        final result = await getHandler.handle({
          'id': taskId,
          'pushNotificationConfigId': configId,
        });

        expect(result, isA<SingleResult>());
        expect((result as SingleResult).data, equals(taskPushConfig.toJson()));
      });

      test('should throw if config not found', () async {
        expect(
          () => getHandler.handle({
            'id': taskId,
            'pushNotificationConfigId': configId,
          }),
          throwsA(
            isA<A2AServerException>().having((e) => e.code, 'code', -32001),
          ),
        );
      });
    });

    group('ListPushConfigsHandler', () {
      test('should list push configs successfully', () async {
        await fakeTaskManager.setPushNotificationConfig(taskId, pushConfig);

        final result = await listHandler.handle({'id': taskId});

        expect(result, isA<SingleResult>());
        expect(
          (result as SingleResult).data,
          equals({
            'configs': <Map<String, Object?>>[pushConfig.toJson()],
          }),
        );
      });

      test('should return empty list if no configs', () async {
        final result = await listHandler.handle({'id': taskId});
        expect(result, isA<SingleResult>());
        expect(
          (result as SingleResult).data,
          equals({'configs': <Map<String, Object?>>[]}),
        );
      });

      test('should throw if task not found', () async {
        fakeTaskManager.taskToReturn = null;
        expect(
          () => listHandler.handle({'id': taskId}),
          throwsA(
            isA<A2AServerException>().having((e) => e.code, 'code', -32001),
          ),
        );
      });
    });

    group('DeletePushConfigHandler', () {
      test('should delete push config successfully', () async {
        await fakeTaskManager.setPushNotificationConfig(taskId, pushConfig);
        expect(
          await fakeTaskManager.getPushNotificationConfig(taskId, configId),
          equals(pushConfig),
        );

        final result = await deleteHandler.handle({
          'id': taskId,
          'pushNotificationConfigId': configId,
        });

        expect(result, isA<SingleResult>());
        expect((result as SingleResult).data, equals(<String, Object?>{}));
        expect(
          await fakeTaskManager.getPushNotificationConfig(taskId, configId),
          isNull,
        );
      });

      test('should throw if task not found', () async {
        fakeTaskManager.taskToReturn = null;
        expect(
          () => deleteHandler.handle({
            'id': taskId,
            'pushNotificationConfigId': configId,
          }),
          throwsA(
            isA<A2AServerException>().having((e) => e.code, 'code', -32001),
          ),
        );
      });

      test('should not throw if config not found', () async {
        // Config not set
        final result = await deleteHandler.handle({
          'id': taskId,
          'pushNotificationConfigId': configId,
        });
        expect(result, isA<SingleResult>());
        expect((result as SingleResult).data, equals(<String, Object?>{}));
      });
    });
  });
}
