// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2a_dart/a2a_dart.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final log = Logger('A2AClient');
  final transport = SseTransport(url: 'http://localhost:8080', log: log);
  final client = A2AClient(url: 'http://localhost:8080', transport: transport);

  try {
    final agentCard = await client.getAgentCard();
    print('Agent: ${agentCard.name}');

    final startMessage = Message(
      messageId: const Uuid().v4(),
      role: Role.user,
      parts: [const Part.text(text: 'start 10')],
    );
    final task = await client.createTask(startMessage);
    print('Created task: ${task.id}');

    final stream = client.executeTask(task.id);
    var pauseSent = false;
    await for (final event in stream) {
      await event.when(
        taskStatusUpdate: (kind, taskId, contextId, status, final_) {},
        taskArtifactUpdate:
            (kind, taskId, contextId, artifact, append, lastChunk) async {
              final part = artifact.parts.first;
              if (part is TextPart) {
                final text = part.text;
                print('Received event: $text');
                if (text.contains('5') && !pauseSent) {
                  pauseSent = true;
                  print('Pausing countdown');
                  final pauseMessage = Message(
                    messageId: const Uuid().v4(),
                    role: Role.user,
                    parts: [Part.text(text: 'pause ${task.id}')],
                  );
                  await client.message(pauseMessage);
                }
              }
            },
      );
    }
  } on A2AException catch (e) {
    e.when(
      jsonRpc: (code, message, data) => print('JSON-RPC Error: $message'),
      http: (statusCode, reason) => print('HTTP Error: $statusCode'),
      network: (message) => print('Network Error: $message'),
      parsing: (message) => print('Parsing Error: $message'),
    );
  }
}
