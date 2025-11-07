// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import '../core/list_tasks_params.dart';
import '../core/list_tasks_result.dart';
import '../core/message.dart';
import '../core/events.dart';
import '../core/task.dart';

/// Manages the lifecycle of A2A tasks.
abstract class TaskManager {
  /// Creates a new task.
  Future<Task> createTask([Message? message]);

  /// Retrieves a task by its ID.
  Future<Task?> getTask(String id);

  /// Adds an event to a task's event stream.
  Future<void> addEvent(String taskId, Event event);

  /// Resubscribes to a task's event stream.
  Stream<Event> resubscribeToTask(String taskId);

  /// Updates a task.
  Future<void> updateTask(Task task);

  /// Cancels a task.
  Future<Task?> cancelTask(String taskId);

  /// Lists tasks, with optional filtering and pagination.
  Future<ListTasksResult> listTasks(ListTasksParams params);


}
