// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../core/events.dart';
import '../core/list_tasks_params.dart';
import '../core/list_tasks_result.dart';
import '../core/message.dart';
import '../core/push_notification.dart';
import '../core/task.dart';

/// Defines the interface for managing the lifecycle of A2A tasks.
///
/// Implementations of this interface are responsible for creating, retrieving,
/// updating, and deleting tasks, as well as managing associated events and
/// push notification configurations.
abstract class TaskManager {
  /// Creates a new task, optionally initialized with a starting [Message].
  ///
  /// Returns the newly created [Task].
  Future<Task> createTask([Message? message]);

  /// Retrieves a [Task] by its unique [id].
  ///
  /// Returns the [Task] if found, otherwise `null`.
  Future<Task?> getTask(String id);

  /// Appends an [Event] to the event stream of a task identified by [taskId].
  ///
  /// This is used for tasks that produce streaming outputs.
  Future<void> addEvent(String taskId, Event event);

  /// Returns a stream of past and future [Event]s for a task identified by
  /// [taskId].
  ///
  /// This allows clients to resubscribe to a task's event stream.
  Stream<Event> resubscribeToTask(String taskId);

  /// Updates the state of an existing [Task].
  ///
  /// The task to be updated is identified by `task.id`.
  Future<void> updateTask(Task task);

  /// Attempts to cancel a task identified by [taskId].
  ///
  /// Returns the updated [Task] with a `canceled` state if successful,
  /// otherwise `null` if the task was not found.
  Future<Task?> cancelTask(String taskId);

  /// Retrieves a list of tasks, with optional filtering and pagination.
  ///
  /// The [params] object specifies the filtering and pagination criteria.
  /// Returns a [ListTasksResult] containing the tasks and pagination info.
  Future<ListTasksResult> listTasks(ListTasksParams params);

  /// Sets or updates a push notification configuration for a task.
  ///
  /// The [taskId] specifies the task, and [config] contains the push
  /// notification details.
  Future<void> setPushNotificationConfig(
    String taskId,
    PushNotificationConfig config,
  );

  /// Retrieves a specific push notification configuration by its [configId]
  /// for a given [taskId].
  ///
  /// Returns the [PushNotificationConfig] if found, otherwise `null`.
  Future<PushNotificationConfig?> getPushNotificationConfig(
    String taskId,
    String configId,
  );

  /// Lists all push notification configurations associated with a [taskId].
  Future<List<PushNotificationConfig>> listPushNotificationConfigs(
    String taskId,
  );

  /// Deletes a specific push notification configuration by its [configId]
  /// for a given [taskId].
  Future<void> deletePushNotificationConfig(String taskId, String configId);
}
