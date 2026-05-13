// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_a2a/src/a2a/a2a.dart';

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

    test('Message copyWith works', () {
      const message = Message(
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
        messageId: '12345',
      );
      final copy = message.copyWith(role: Role.agent);
      expect(copy.role, Role.agent);
      expect(copy.messageId, '12345');
    });

    test('Message toString works', () {
      const message = Message(
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
        messageId: '12345',
      );
      expect(message.toString(), contains('Message'));
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

    test('Task copyWith works', () {
      const task = Task(
        id: 'task-123',
        contextId: 'context-456',
        status: TaskStatus(state: TaskState.working),
      );
      final copy = task.copyWith(status: const TaskStatus(state: TaskState.completed));
      expect(copy.status.state, TaskState.completed);
      expect(copy.id, 'task-123');
    });

    test('Task toString works', () {
      const task = Task(
        id: 'task-123',
        contextId: 'context-456',
        status: TaskStatus(state: TaskState.working),
      );
      expect(task.toString(), contains('Task'));
    });

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

    test('Part copyWith works', () {
      const part = TextPart(text: 'Hello');
      final copy = part.copyWith(text: 'New Hello');
      expect(copy.text, 'New Hello');
    });

    test('Part toString works', () {
      const part = Part.text(text: 'Hello');
      expect(part.toString(), contains('TextPart'));
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
    test('AgentExtension can be serialized and deserialized', () {
      final extension = const AgentExtension(
        uri: 'https://example.com/ext',
        description: 'Test extension',
        required: true,
        params: {'key': 'value'},
      );

      final Map<String, dynamic> json = extension.toJson();
      final newExtension = AgentExtension.fromJson(json);

      expect(newExtension, equals(extension));
    });

    test('AgentExtension copyWith works', () {
      const extension = AgentExtension(
        uri: 'https://example.com/ext',
        description: 'Test extension',
        required: true,
      );
      final copy = extension.copyWith(required: false);
      expect(copy.required, false);
      expect(copy.uri, 'https://example.com/ext');
    });

    test('AgentExtension toString works', () {
      const extension = AgentExtension(
        uri: 'https://example.com/ext',
        description: 'Test extension',
        required: true,
      );
      expect(extension.toString(), contains('AgentExtension'));
    });
    test('AgentInterface can be serialized and deserialized', () {
      const interface = AgentInterface(
        url: 'https://example.com/a2a',
        transport: TransportProtocol.jsonrpc,
      );

      final Map<String, dynamic> json = interface.toJson();
      final newInterface = AgentInterface.fromJson(json);

      expect(newInterface, equals(interface));
    });

    test('AgentInterface copyWith works', () {
      const interface = AgentInterface(
        url: 'https://example.com/a2a',
        transport: TransportProtocol.jsonrpc,
      );
      final copy = interface.copyWith(url: 'https://example.com/new');
      expect(copy.url, 'https://example.com/new');
      expect(copy.transport, TransportProtocol.jsonrpc);
    });

    test('AgentInterface toString works', () {
      const interface = AgentInterface(
        url: 'https://example.com/a2a',
        transport: TransportProtocol.jsonrpc,
      );
      expect(interface.toString(), contains('AgentInterface'));
    });
    test('ListTasksParams can be serialized and deserialized', () {
      final params = const ListTasksParams(
        contextId: 'context-123',
        status: TaskState.working,
        pageSize: 20,
        pageToken: 'token-456',
        historyLength: 5,
        lastUpdatedAfter: 123456789,
        includeArtifacts: true,
        metadata: {'key': 'value'},
      );

      final Map<String, dynamic> json = params.toJson();
      final newParams = ListTasksParams.fromJson(json);

      expect(newParams, equals(params));
    });

    test('ListTasksParams copyWith works', () {
      const params = ListTasksParams(contextId: 'context-123');
      final copy = params.copyWith(pageSize: 10);
      expect(copy.pageSize, 10);
      expect(copy.contextId, 'context-123');
    });

    test('ListTasksParams toString works', () {
      const params = ListTasksParams(contextId: 'context-123');
      expect(params.toString(), contains('ListTasksParams'));
    });
    test('AgentCapabilities can be serialized and deserialized', () {
      final capabilities = const AgentCapabilities(
        streaming: true,
        pushNotifications: true,
        stateTransitionHistory: true,
        extensions: [
          AgentExtension(uri: 'https://example.com/ext', description: 'Test')
        ],
      );

      final Map<String, dynamic> json = capabilities.toJson();
      final newCapabilities = AgentCapabilities.fromJson(json);

      expect(newCapabilities, equals(capabilities));
    });

    test('AgentCapabilities copyWith works', () {
      const capabilities = AgentCapabilities(streaming: true);
      final copy = capabilities.copyWith(streaming: false);
      expect(copy.streaming, false);
    });

    test('AgentCapabilities toString works', () {
      const capabilities = AgentCapabilities(streaming: true);
      expect(capabilities.toString(), contains('AgentCapabilities'));
    });
  });
}
