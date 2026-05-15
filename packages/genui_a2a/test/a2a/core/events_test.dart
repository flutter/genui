// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2a/src/a2a/a2a.dart';

void main() {
  group('Event', () {
    test('StatusUpdate fromJson and toJson', () {
      final Map<String, Object> json = {
        'kind': 'status-update',
        'taskId': 'task-123',
        'contextId': 'context-123',
        'status': {'state': 'working', 'message': null, 'timestamp': null},
        'final': false,
      };
      final event = Event.fromJson(json) as StatusUpdate;
      expect(event.taskId, 'task-123');
      expect(event.contextId, 'context-123');
      expect(event.status.state, TaskState.working);
      expect(event.final_, false);
      expect(event.toJson(), json);
    });

    test('StatusUpdate copyWith', () {
      const event = StatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      final StatusUpdate copy = event.copyWith(final_: true);
      expect(copy.final_, true);
    });

    test('TaskStatusUpdate fromJson and toJson', () {
      final Map<String, Object> json = {
        'kind': 'task-status-update',
        'taskId': 'task-123',
        'contextId': 'context-123',
        'status': {'state': 'working', 'message': null, 'timestamp': null},
        'final': false,
      };
      final event = Event.fromJson(json) as TaskStatusUpdate;
      expect(event.taskId, 'task-123');
      expect(event.toJson(), json);
    });

    test('ArtifactUpdate fromJson and toJson', () {
      final Map<String, Object> json = {
        'kind': 'artifact-update',
        'taskId': 'task-123',
        'contextId': 'context-123',
        'artifact': {
          'artifactId': 'artifact-123',
          'name': null,
          'description': null,
          'parts': [
            {'kind': 'text', 'metadata': null, 'text': 'hello'},
          ],
          'metadata': null,
          'extensions': null,
        },
        'append': false,
        'lastChunk': true,
      };
      final event = Event.fromJson(json) as ArtifactUpdate;
      expect(event.taskId, 'task-123');
      expect(event.artifact.artifactId, 'artifact-123');
      expect(event.toJson(), json);
    });

    test('Event.fromJson throws on unknown kind', () {
      final json = {'kind': 'unknown'};
      expect(() => Event.fromJson(json), throwsArgumentError);
    });
    test('StatusUpdate operator == and hashCode', () {
      const event1 = StatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      const event2 = StatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      expect(event1, event2);
      expect(event1.hashCode, event2.hashCode);
    });

    test('StatusUpdate toString', () {
      const event = StatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      expect(event.toString(), contains('StatusUpdate'));
    });

    test('TaskStatusUpdate operator == and hashCode', () {
      const event1 = TaskStatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      const event2 = TaskStatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      expect(event1, event2);
      expect(event1.hashCode, event2.hashCode);
    });

    test('TaskStatusUpdate toString', () {
      const event = TaskStatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      expect(event.toString(), contains('TaskStatusUpdate'));
    });

    test('ArtifactUpdate copyWith', () {
      const event = ArtifactUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        artifact: Artifact(artifactId: 'art-1', parts: []),
        append: false,
        lastChunk: false,
      );
      final ArtifactUpdate copy = event.copyWith(append: true);
      expect(copy.append, true);
    });

    test('ArtifactUpdate operator == and hashCode', () {
      const event1 = ArtifactUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        artifact: Artifact(artifactId: 'art-1', parts: []),
        append: false,
        lastChunk: false,
      );
      const event2 = ArtifactUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        artifact: Artifact(artifactId: 'art-1', parts: []),
        append: false,
        lastChunk: false,
      );
      expect(event1, event2);
      expect(event1.hashCode, event2.hashCode);
    });

    test('ArtifactUpdate toString', () {
      const event = ArtifactUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        artifact: Artifact(artifactId: 'art-1', parts: []),
        append: false,
        lastChunk: false,
      );
      expect(event.toString(), contains('ArtifactUpdate'));
    });
    test('StatusUpdate copyWith without arguments works', () {
      const event = StatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      final StatusUpdate copy = event.copyWith();
      expect(copy.taskId, 'task-123');
    });

    test('TaskStatusUpdate copyWith without arguments works', () {
      const event = TaskStatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
      );
      final TaskStatusUpdate copy = event.copyWith();
      expect(copy.taskId, 'task-123');
    });

    test('ArtifactUpdate copyWith without arguments works', () {
      const event = ArtifactUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        artifact: Artifact(artifactId: 'art-1', parts: []),
        append: false,
        lastChunk: false,
      );
      final ArtifactUpdate copy = event.copyWith();
      expect(copy.taskId, 'task-123');
    });
    test('StatusUpdate operator == returns false for different taskId', () {
      const event1 = StatusUpdate(
        taskId: 'task1',
        contextId: 'context1',
        status: TaskStatus(state: TaskState.working),
      );
      const event2 = StatusUpdate(
        taskId: 'task2',
        contextId: 'context1',
        status: TaskStatus(state: TaskState.working),
      );
      expect(event1 == event2, isFalse);
    });

    test('ArtifactUpdate operator == returns false for different taskId', () {
      const event1 = ArtifactUpdate(
        taskId: 'task1',
        contextId: 'context1',
        artifact: Artifact(artifactId: 'art1', parts: []),
        append: false,
        lastChunk: false,
      );
      const event2 = ArtifactUpdate(
        taskId: 'task2',
        contextId: 'context1',
        artifact: Artifact(artifactId: 'art1', parts: []),
        append: false,
        lastChunk: false,
      );
      expect(event1 == event2, isFalse);
    });
  });
}
