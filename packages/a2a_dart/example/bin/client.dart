// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:a2a_dart/a2a_dart.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// This is an example of how to write a client for the A2A protocol.
/// It demonstrates the use of the A2AClient class to connect to an A2A server
/// and perform various operations.
///
/// It connects to the server and asks it to start a countdown from 10 to zero.
/// Then at 5 it demonstrates how to pause the countdown, and then resumes it
/// after a three second pause.
void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final log = Logger('A2AClientExample');

  await Future<void>.delayed(const Duration(seconds: 1));

  final client = A2AClient(
    url: 'http://localhost:8080',
    transport: HttpTransport(url: 'http://localhost:8080', log: log),
    log: log,
  );

  try {
    final agentCard = await client.getAgentCard();
    print('Agent: ${agentCard.name}');

    final message = Message(
      messageId: const Uuid().v4(),
      role: Role.user,
      parts: const [Part.text(text: 'start 10')],
    );
    final stream = client.messageStream(message);
    String? taskId;

    await for (final event in stream) {
      taskId ??= event.taskId;
      switch (event) {
        case TaskStatusUpdate():
          final task = await client.getTask(event.taskId);
          print('Task ${task.id} updated: ${task.status.state.name}');
          break;
        case TaskArtifactUpdate():
          for (final part in event.artifact.parts) {
            if (part is TextPart) {
              print(part.text);
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
    }

    print('---');

    // Demonstrate messageSend
    final task2 = await client.messageSend(
      Message(
        messageId: const Uuid().v4(),
        role: Role.user,
        parts: const [Part.text(text: 'pause')],
      ),
    );
    print('Created task ${task2.id}');

    // Demonstrate listTasks
    final tasks = await client.listTasks();
    print('Found ${tasks.tasks.length} tasks:');
    for (final t in tasks.tasks) {
      print('  - ${t.id}');
      final task = await client.getTask(t.id);
      // cancel the task
      final canceledTask = await client.cancelTask(task.id);
      print('    - Canceled task: ${canceledTask.id}');
    }
  } on A2AException catch (exception) {
    print('Error: $exception');
    exit(1);
  } finally {
    client.close();
    exit(0);
  }
}
