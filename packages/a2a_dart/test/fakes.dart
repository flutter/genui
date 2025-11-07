// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:a2a_dart/a2a_dart.dart';
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
}

class FakeTaskManager implements TaskManager {
  final _events = <String, List<Event>>{};
  final Task? taskToReturn;
  final Stream<Map<String, Object?>>? stream;

  FakeTaskManager({this.taskToReturn, this.stream});

  @override
  Future<Task> createTask([Message? message]) async => taskToReturn!;

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
  Future<Task?> getTask(String taskId) async => taskToReturn;

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


}

Response ok(Map<String, Object?> body) {
  return Response.ok(
    jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}
