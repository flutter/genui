// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2ui/src/a2a/a2a.dart';

import '../fakes.dart';

void main() {
  group('A2AClient Compliance', () {
    late A2AClient client;
    late FakeTransport transport;

    setUp(() {
      transport = FakeTransport(response: {});
      client = A2AClient(url: 'http://example.com', transport: transport);
    });

    test('listTasks sends correct request and parses response', () async {
      final params = const ListTasksParams(pageSize: 10);
      final result = const ListTasksResult(
        tasks: [],
        totalSize: 0,
        pageSize: 10,
        nextPageToken: '',
      );
      transport.response['result'] = result.toJson();

      final ListTasksResult response = await client.listTasks(params);

      expect(response.tasks, isEmpty);
      expect(response.nextPageToken, isEmpty);
    });

    test('setPushNotificationConfig sends correct request', () async {
      final config = const TaskPushNotificationConfig(
        taskId: 'task-123',
        pushNotificationConfig: PushNotificationConfig(
          id: 'config-123',
          url: 'http://example.com/push',
        ),
      );
      transport.response['result'] = config.toJson();

      await client.setPushNotificationConfig(config);
    });

    test('getPushNotificationConfig sends correct request', () async {
      final config = const TaskPushNotificationConfig(
        taskId: 'task-123',
        pushNotificationConfig: PushNotificationConfig(
          id: 'config-123',
          url: 'http://example.com/push',
        ),
      );
      transport.response['result'] = config.toJson();

      await client.getPushNotificationConfig('task-123', 'config-123');
    });

    test('listPushNotificationConfigs sends correct request', () async {
      transport.response['result'] = {'configs': <Map<String, Object?>>[]};

      final List<PushNotificationConfig> response = await client
          .listPushNotificationConfigs('task-123');

      expect(response, isEmpty);
    });

    test('deletePushNotificationConfig sends correct request', () async {
      transport.response['result'] = {};

      await client.deletePushNotificationConfig('task-123', 'config-123');
    });

    test('authHeaders are passed to transport', () async {
      final authHeaders = {'Authorization': 'Bearer test-token'};
      transport = FakeTransport(response: {}, authHeaders: authHeaders);
      client = A2AClient(url: 'http://example.com', transport: transport);

      expect(transport.authHeaders, equals(authHeaders));
    });

    test('correct exception is thrown for generic JSON-RPC error', () {
      transport.response['error'] = {
        'code': -32600,
        'message': 'Invalid Request',
      };

      expect(
        () => client.getTask('bad-task-id'),
        throwsA(isA<A2AJsonRpcException>()),
      );
    });

    test('correct exception is thrown for A2A error codes', () {
      transport.response['error'] = {
        'code': -32001,
        'message': 'Task not found',
      };

      expect(
        () => client.getTask('bad-task-id'),
        throwsA(isA<A2ATaskNotFoundException>()),
      );
    });
  });
}
