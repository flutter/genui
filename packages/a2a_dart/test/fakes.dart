// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:a2a_dart/src/core/push_notification.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

class FakeHttpClient implements http.Client {
  final Map<String, Object?> response;
  final int statusCode;

  FakeHttpClient(this.response, {this.statusCode = 200});

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return http.Response(jsonEncode(response), statusCode);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return http.Response(jsonEncode(response), statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransport implements Transport {
  final Map<String, Object?> response;
  final Stream<Map<String, Object?>> stream;

  FakeTransport({required this.response, Stream<Map<String, Object?>>? stream})
    : stream = stream ?? Stream.value(response);

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    return response;
  }

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = '/rpc',
  }) async {
    return response;
  }

  @override
  Stream<Map<String, Object?>> sendStream(Map<String, Object?> request) {
    return stream;
  }

  @override
  void close() {}
}

class FakeTaskManager implements TaskManager {
  final _events = <String, List<Event>>{};
  final _pushConfigs = <String, Map<String, PushNotificationConfig>>{};
  Task? taskToReturn;
  final Stream<Map<String, Object?>>? stream;

  FakeTaskManager({this.taskToReturn, this.stream});

  @override
  Future<Task> createTask([Message? message]) async {
    final task =
        taskToReturn ??
        const Task(
          id: 'default-task-id',
          contextId: 'default-context',
          status: TaskStatus(state: TaskState.working),
        );
    if (_events.containsKey(task.id)) {
      throw Exception('Task with id ${task.id} already exists');
    }
    _events[task.id] = [];
    _pushConfigs[task.id] = {};
    taskToReturn = task; // Set this for subsequent getTask calls if needed
    return task;
  }

  // Helper to ensure task exists in tests
  Future<void> ensureTaskExists(Task task) async {
    if (!_events.containsKey(task.id)) {
      _events[task.id] = [];
      _pushConfigs[task.id] = {};
    }
  }

  @override
  Stream<Event> resubscribeToTask(String taskId) {
    return Stream.fromIterable(_events[taskId] ?? []);
  }

  @override
  Future<void> addEvent(String taskId, Event event) async {
    _events.putIfAbsent(taskId, () => []).add(event);
  }

  @override
  Future<void> updateTask(Task task) async {}

  @override
  Future<Task?> getTask(String taskId) async {
    return _events.containsKey(taskId) ? taskToReturn : null;
  }

  @override
  Future<Task?> cancelTask(String taskId) async {
    return taskToReturn?.copyWith(
      status: const TaskStatus(state: TaskState.canceled),
    );
  }

  @override
  Future<ListTasksResult> listTasks(ListTasksParams params) async {
    return ListTasksResult(
      tasks: [if (taskToReturn != null) taskToReturn!],
      totalSize: taskToReturn == null ? 0 : 1,
      pageSize: 1,
      nextPageToken: '',
    );
  }

  @override
  Future<void> setPushNotificationConfig(
    String taskId,
    PushNotificationConfig config,
  ) async {
    _pushConfigs[taskId]?[config.id!] = config;
  }

  @override
  Future<PushNotificationConfig?> getPushNotificationConfig(
    String taskId,
    String configId,
  ) async => _pushConfigs[taskId]?[configId];

  @override
  Future<List<PushNotificationConfig>> listPushNotificationConfigs(
    String taskId,
  ) async => _pushConfigs[taskId]?.values.toList() ?? [];

  @override
  Future<void> deletePushNotificationConfig(
    String taskId,
    String configId,
  ) async {
    _pushConfigs[taskId]?.remove(configId);
  }
}

Response ok(Map<String, Object?> body) {
  return Response.ok(
    jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}
