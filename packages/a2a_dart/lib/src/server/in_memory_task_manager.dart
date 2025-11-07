// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:uuid/uuid.dart';

import '../../a2a_dart.dart';

/// An in-memory implementation of the [TaskManager] interface.
class InMemoryTaskManager implements TaskManager {
  final _tasks = <String, Task>{};
  final _events = <String, List<Event>>{};
  final _uuid = const Uuid();

  @override
  @override
  Future<Task> createTask([Message? message]) async {
    final taskId = _uuid.v4();
    final contextId = _uuid.v4();
    final task = Task(
      id: taskId,
      contextId: contextId,
      history: [if (message != null) message],
      status: const TaskStatus(state: TaskState.submitted),
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
    _tasks[taskId] = task;
    return task;
  }

  @override
  @override
  Future<Task?> getTask(String id) async => _tasks[id];

  @override
  @override
  Future<void> updateTask(Task task) async {
    _tasks[task.id] = task.copyWith(
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  @override
  Future<Task?> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      final canceledTask = task.copyWith(
        status: const TaskStatus(state: TaskState.canceled),
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
      _tasks[taskId] = canceledTask;
      return canceledTask;
    }
    return null;
  }

  @override
  @override
  Future<ListTasksResult> listTasks(ListTasksParams params) async {
    var tasks = _tasks.values.toList();

    if (params.contextId != null) {
      tasks = tasks.where((t) => t.contextId == params.contextId).toList();
    }
    if (params.status != null) {
      tasks = tasks.where((t) => t.status.state == params.status).toList();
    }
    if (params.lastUpdatedAfter != null) {
      tasks = tasks
          .where((t) =>
              t.lastUpdated != null &&
              t.lastUpdated! > params.lastUpdatedAfter!)
          .toList();
    }

    tasks.sort((a, b) => b.lastUpdated!.compareTo(a.lastUpdated!));

    final totalSize = tasks.length;
    final pageToken =
        params.pageToken != null ? int.parse(params.pageToken!) : 0;
    final startIndex = pageToken * params.pageSize;
    final endIndex = (startIndex + params.pageSize > totalSize)
        ? totalSize
        : startIndex + params.pageSize;

    final paginatedTasks = tasks.sublist(startIndex, endIndex);

    final nextPageToken =
        endIndex < totalSize ? (pageToken + 1).toString() : '';

    return ListTasksResult(
      tasks: paginatedTasks,
      totalSize: totalSize,
      pageSize: params.pageSize,
      nextPageToken: nextPageToken,
    );
  }

  @override
  Stream<Event> resubscribeToTask(String taskId) {
    return Stream.fromIterable(_events[taskId] ?? []);
  }

  @override
  Future<void> addEvent(String taskId, Event event) async {
    _events.putIfAbsent(taskId, () => []).add(event);
  }
}
