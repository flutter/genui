// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2ui/src/a2a/a2a.dart';
import 'package:uuid/uuid.dart';

import 'fake_transport.dart';

void main() {
  test('example client and server', () async {
    final transport = FakeTransport();
    final client = A2AClient(url: 'http://localhost/', transport: transport);
    addTearDown(client.close);

    final message = Message(
      messageId: const Uuid().v4(),
      role: Role.user,
      parts: const [Part.text(text: 'start 10')],
    );
    final Stream<Event> stream = client.messageStream(message);
    String? taskId;
    final events = <String>[];

    final completer = Completer<void>();

    stream.listen((event) {
      taskId ??= event.taskId;
      if (event is ArtifactUpdate) {
        for (final Part part in event.artifact.parts) {
          if (part is TextPart) {
            events.add(part.text);
            if (part.text.contains('Countdown at 5')) {
              unawaited(
                client.messageSend(
                  Message(
                    messageId: const Uuid().v4(),
                    role: Role.user,
                    parts: const [Part.text(text: 'pause')],
                    taskId: taskId,
                  ),
                ),
              );
            }
          }
        }
      }
    }, onDone: completer.complete);

    transport.addEvent(
      const Event.taskStatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.working),
        final_: false,
      ),
    );

    for (var i = 10; i >= 0; i--) {
      transport.addEvent(
        Event.artifactUpdate(
          taskId: 'task-123',
          contextId: 'context-123',
          artifact: Artifact(
            artifactId: 'artifact-$i',
            parts: [Part.text(text: 'Countdown at $i!')],
          ),
          append: false,
          lastChunk: i == 0,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    transport.addEvent(
      const Event.taskStatusUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        status: TaskStatus(state: TaskState.completed),
        final_: true,
      ),
    );
    transport.addEvent(
      const Event.artifactUpdate(
        taskId: 'task-123',
        contextId: 'context-123',
        artifact: Artifact(
          artifactId: 'artifact-liftoff',
          parts: [Part.text(text: 'Liftoff!')],
        ),
        append: false,
        lastChunk: true,
      ),
    );
    transport.close();

    await completer.future;

    expect(events.join('\n'), contains('Countdown at 5'));
    expect(events.join('\n'), contains('Liftoff!'));
  });
}
