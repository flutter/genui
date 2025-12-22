// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2ui/src/a2a/a2a.dart';

void main() {
  group('Data Models', () {
    test('AgentCard can be serialized and deserialized', () {
      final agentCard = const AgentCard(
        protocolVersion: '1.0',
        name: 'Test Agent',
        description: 'An agent for testing',
        url: 'https://example.com/agent',
        version: '1.0.0',
        capabilities: AgentCapabilities(),
        defaultInputModes: ['text'],
        defaultOutputModes: ['text'],
        skills: [],
      );

      final Map<String, dynamic> json = agentCard.toJson();
      final newAgentCard = AgentCard.fromJson(json);

      expect(newAgentCard, equals(agentCard));
      expect(newAgentCard.name, equals('Test Agent'));
    });

    test('AgentCard with optional fields null can be serialized and '
        'deserialized', () {
      final agentCard = const AgentCard(
        protocolVersion: '1.0',
        name: 'Test Agent',
        description: 'An agent for testing',
        url: 'https://example.com/agent',
        version: '1.0.0',
        capabilities: AgentCapabilities(),
        defaultInputModes: [],
        defaultOutputModes: [],
        skills: [],
      );

      final Map<String, dynamic> json = agentCard.toJson();
      final newAgentCard = AgentCard.fromJson(json);

      expect(newAgentCard, equals(agentCard));
    });

    test('Message can be serialized and deserialized', () {
      final message = const Message(
        role: Role.user,
        parts: [Part.text(text: 'Hello, agent!')],
        messageId: '12345',
      );

      final Map<String, dynamic> json = message.toJson();
      final newMessage = Message.fromJson(json);

      expect(newMessage, equals(message));
      expect(newMessage.role, equals(Role.user));
    });

    test('Message with empty parts can be serialized and deserialized', () {
      final message = const Message(
        role: Role.user,
        parts: [],
        messageId: '12345',
      );

      final Map<String, dynamic> json = message.toJson();
      final newMessage = Message.fromJson(json);

      expect(newMessage, equals(message));
    });

    test('Message with multiple parts can be serialized and deserialized', () {
      final message = const Message(
        role: Role.user,
        parts: [
          Part.text(text: 'Hello'),
          Part.file(
            file: FileType.uri(
              uri: 'file:///path/to/file.txt',
              mimeType: 'text/plain',
            ),
          ),
          Part.data(data: {'key': 'value'}),
        ],
        messageId: '12345',
      );

      final Map<String, dynamic> json = message.toJson();
      final newMessage = Message.fromJson(json);

      expect(newMessage, equals(message));
    });

    test('Task can be serialized and deserialized', () {
      final task = const Task(
        id: 'task-123',
        contextId: 'context-456',
        status: TaskStatus(state: TaskState.working),
        artifacts: [
          Artifact(
            artifactId: 'artifact-1',
            parts: [Part.text(text: 'Hello')],
          ),
        ],
      );

      final Map<String, dynamic> json = task.toJson();
      final newTask = Task.fromJson(json);

      expect(newTask, equals(task));
      expect(newTask.id, equals('task-123'));
    });

    test(
      'Task with optional fields null can be serialized and deserialized',
      () {
        final task = const Task(
          id: 'task-123',
          contextId: 'context-456',
          status: TaskStatus(state: TaskState.working),
        );

        final Map<String, dynamic> json = task.toJson();
        final newTask = Task.fromJson(json);

        expect(newTask, equals(task));
      },
    );

    test('Part can be serialized and deserialized', () {
      final partText = const Part.text(text: 'Hello');
      final Map<String, dynamic> jsonText = partText.toJson();
      final newPartText = Part.fromJson(jsonText);
      expect(newPartText, equals(partText));

      final partFileUri = const Part.file(
        file: FileType.uri(
          uri: 'file:///path/to/file.txt',
          mimeType: 'text/plain',
        ),
      );
      final Map<String, dynamic> jsonFileUri = partFileUri.toJson();
      final newPartFileUri = Part.fromJson(jsonFileUri);
      expect(newPartFileUri, equals(partFileUri));

      final partFileBytes = const Part.file(
        file: FileType.bytes(
          bytes: 'aGVsbG8=', // base64 for "hello"
          name: 'hello.txt',
        ),
      );
      final Map<String, dynamic> jsonFileBytes = partFileBytes.toJson();
      final newPartFileBytes = Part.fromJson(jsonFileBytes);
      expect(newPartFileBytes, equals(partFileBytes));

      final partData = const Part.data(data: {'key': 'value'});
      final Map<String, dynamic> jsonData = partData.toJson();
      final newPartData = Part.fromJson(jsonData);
      expect(newPartData, equals(partData));
    });

    test('SecurityScheme can be serialized and deserialized', () {
      final securityScheme = const SecurityScheme.apiKey(
        name: 'test_key',
        in_: 'header',
      );

      final Map<String, dynamic> json = securityScheme.toJson();
      final newSecurityScheme = SecurityScheme.fromJson(json);

      expect(newSecurityScheme, equals(securityScheme));
    });

    test('PushNotificationConfig can be serialized and deserialized', () {
      final config = const PushNotificationConfig(
        id: 'config-1',
        url: 'https://example.com/push',
        authentication: PushNotificationAuthenticationInfo(
          schemes: ['Bearer'],
          credentials: 'test-token',
        ),
      );

      final Map<String, dynamic> json = config.toJson();
      final newConfig = PushNotificationConfig.fromJson(json);

      expect(newConfig, equals(config));
    });

    test('TaskPushNotificationConfig can be serialized and deserialized', () {
      final taskConfig = const TaskPushNotificationConfig(
        taskId: 'task-123',
        pushNotificationConfig: PushNotificationConfig(
          id: 'config-1',
          url: 'https://example.com/push',
        ),
      );

      final Map<String, dynamic> json = taskConfig.toJson();
      final newTaskConfig = TaskPushNotificationConfig.fromJson(json);

      expect(newTaskConfig, equals(taskConfig));
    });
  });
}
