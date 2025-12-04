// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:a2a_dart/src/core/push_notification.dart';
import 'package:http/http.dart';

class FakeTransport extends Transport {
  Map<String, Object?> response;
  final Stream<Map<String, Object?>>? stream;
  @override
  final Map<String, String> authHeaders;

  FakeTransport({
    required this.response,
    this.stream,
    this.authHeaders = const {},
  });

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = '/rpc',
  }) async {
    return response;
  }

  @override
  Stream<Map<String, Object?>> sendStream(Map<String, Object?> request) {
    if (stream == null) {
      throw UnimplementedError();
    }
    return stream!;
  }

  @override
  void close() {}

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    return response;
  }
}

class FakeHttpClient implements Client {
  final Map<String, Object?> response;
  final int statusCode;

  FakeHttpClient(this.response, {this.statusCode = 200});

  @override
  Future<Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return Response(
      jsonEncode(response),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    return Response(
      jsonEncode(response),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTaskManager implements TaskManager {
  Task? taskToReturn;
  final Map<String, Map<String, PushNotificationConfig>> _pushConfigs = {};

  FakeTaskManager({this.taskToReturn});

  void ensureTaskExists(String taskId) {
    if (taskToReturn?.id != taskId) {
      throw const A2AException.taskNotFound(message: 'Task not found');
    }
  }

  @override
  Future<Task> createTask([Message? message]) async {
    return taskToReturn!;
  }

  @override
  Future<void> addEvent(String taskId, Event event) async {}

  @override
  Future<void> updateTask(Task task) async {}

  @override
  Future<Task?> getTask(String id) async {
    return taskToReturn;
  }

  @override
  Future<Task?> cancelTask(String id) async {
    return taskToReturn;
  }

  @override
  Stream<Event> resubscribeToTask(String id) {
    return Stream.fromIterable([]);
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
    (_pushConfigs[taskId] ??= {})[config.id!] = config;
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
