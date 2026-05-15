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

      final Map<String, Object?> json = agentCard.toJson();
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

      final Map<String, Object?> json = agentCard.toJson();
      final newAgentCard = AgentCard.fromJson(json);

      expect(newAgentCard, equals(agentCard));
    });

    test('Message can be serialized and deserialized', () {
      final message = const Message(
        role: Role.user,
        parts: [Part.text(text: 'Hello, agent!')],
        messageId: '12345',
      );

      final Map<String, Object?> json = message.toJson();
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

      final Map<String, Object?> json = message.toJson();
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

      final Map<String, Object?> json = message.toJson();
      final newMessage = Message.fromJson(json);

      expect(newMessage, equals(message));
    });

    test('Message copyWith works', () {
      const message = Message(
        role: Role.user,
        parts: [Part.text(text: 'Hello')],
        messageId: '12345',
      );
      final Message copy = message.copyWith(role: Role.agent);
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

      final Map<String, Object?> json = task.toJson();
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

        final Map<String, Object?> json = task.toJson();
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
      final Task copy = task.copyWith(
        status: const TaskStatus(state: TaskState.completed),
      );
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
      final Map<String, Object?> jsonText = partText.toJson();
      final newPartText = Part.fromJson(jsonText);
      expect(newPartText, equals(partText));

      final partFileUri = const Part.file(
        file: FileType.uri(
          uri: 'file:///path/to/file.txt',
          mimeType: 'text/plain',
        ),
      );
      final Map<String, Object?> jsonFileUri = partFileUri.toJson();
      final newPartFileUri = Part.fromJson(jsonFileUri);
      expect(newPartFileUri, equals(partFileUri));

      final partFileBytes = const Part.file(
        file: FileType.bytes(
          bytes: 'aGVsbG8=', // base64 for "hello"
          name: 'hello.txt',
        ),
      );
      final Map<String, Object?> jsonFileBytes = partFileBytes.toJson();
      final newPartFileBytes = Part.fromJson(jsonFileBytes);
      expect(newPartFileBytes, equals(partFileBytes));

      final partData = const Part.data(data: {'key': 'value'});
      final Map<String, Object?> jsonData = partData.toJson();
      final newPartData = Part.fromJson(jsonData);
      expect(newPartData, equals(partData));
    });

    test('Part copyWith works', () {
      const part = TextPart(text: 'Hello');
      final TextPart copy = part.copyWith(text: 'New Hello');
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

      final Map<String, Object?> json = securityScheme.toJson();
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

      final Map<String, Object?> json = config.toJson();
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

      final Map<String, Object?> json = taskConfig.toJson();
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

      final Map<String, Object?> json = extension.toJson();
      final newExtension = AgentExtension.fromJson(json);

      expect(newExtension, equals(extension));
    });

    test('AgentExtension copyWith works', () {
      const extension = AgentExtension(
        uri: 'https://example.com/ext',
        description: 'Test extension',
        required: true,
      );
      final AgentExtension copy = extension.copyWith(required: false);
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

      final Map<String, Object?> json = interface.toJson();
      final newInterface = AgentInterface.fromJson(json);

      expect(newInterface, equals(interface));
    });

    test('AgentInterface copyWith works', () {
      const interface = AgentInterface(
        url: 'https://example.com/a2a',
        transport: TransportProtocol.jsonrpc,
      );
      final AgentInterface copy = interface.copyWith(
        url: 'https://example.com/new',
      );
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

      final Map<String, Object?> json = params.toJson();
      final newParams = ListTasksParams.fromJson(json);

      expect(newParams, equals(params));
    });

    test('ListTasksParams copyWith works', () {
      const params = ListTasksParams(contextId: 'context-123');
      final ListTasksParams copy = params.copyWith(pageSize: 10);
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
          AgentExtension(uri: 'https://example.com/ext', description: 'Test'),
        ],
      );

      final Map<String, Object?> json = capabilities.toJson();
      final newCapabilities = AgentCapabilities.fromJson(json);

      expect(newCapabilities, equals(capabilities));
    });

    test('AgentCapabilities copyWith works', () {
      const capabilities = AgentCapabilities(streaming: true);
      final AgentCapabilities copy = capabilities.copyWith(streaming: false);
      expect(copy.streaming, false);
    });

    test('AgentCapabilities toString works', () {
      const capabilities = AgentCapabilities(streaming: true);
      expect(capabilities.toString(), contains('AgentCapabilities'));
    });
    test('ListTasksResult can be serialized and deserialized', () {
      final result = const ListTasksResult(
        tasks: [],
        totalSize: 0,
        pageSize: 50,
        nextPageToken: '',
      );

      final Map<String, Object?> json = result.toJson();
      final newResult = ListTasksResult.fromJson(json);

      expect(newResult, equals(result));
    });

    test('ListTasksResult copyWith works', () {
      const result = ListTasksResult(
        tasks: [],
        totalSize: 0,
        pageSize: 50,
        nextPageToken: '',
      );
      final ListTasksResult copy = result.copyWith(totalSize: 10);
      expect(copy.totalSize, 10);
      expect(copy.pageSize, 50);
    });

    test('ListTasksResult toString works', () {
      const result = ListTasksResult(
        tasks: [],
        totalSize: 0,
        pageSize: 50,
        nextPageToken: '',
      );
      expect(result.toString(), contains('ListTasksResult'));
    });
    test('AgentSkill copyWith works', () {
      const skill = AgentSkill(
        id: 'skill-1',
        name: 'Skill 1',
        description: 'Test skill',
        tags: ['test'],
      );
      final AgentSkill copy = skill.copyWith(name: 'New Name');
      expect(copy.name, 'New Name');
      expect(copy.id, 'skill-1');
    });

    test('AgentSkill toString works', () {
      const skill = AgentSkill(
        id: 'skill-1',
        name: 'Skill 1',
        description: 'Test skill',
        tags: ['test'],
      );
      expect(skill.toString(), contains('AgentSkill'));
    });
    test('PushNotificationConfig copyWith works', () {
      const config = PushNotificationConfig(url: 'https://example.com');
      final PushNotificationConfig copy = config.copyWith(id: 'id-1');
      expect(copy.id, 'id-1');
    });

    test('PushNotificationConfig operator == and hashCode', () {
      const config1 = PushNotificationConfig(url: 'https://example.com');
      const config2 = PushNotificationConfig(url: 'https://example.com');
      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('PushNotificationConfig toString works', () {
      const config = PushNotificationConfig(url: 'https://example.com');
      expect(config.toString(), contains('PushNotificationConfig'));
    });

    test('PushNotificationAuthenticationInfo copyWith works', () {
      const info = PushNotificationAuthenticationInfo(schemes: ['Bearer']);
      final PushNotificationAuthenticationInfo copy = info.copyWith(
        credentials: 'token',
      );
      expect(copy.credentials, 'token');
    });

    test('PushNotificationAuthenticationInfo operator == and hashCode', () {
      const info1 = PushNotificationAuthenticationInfo(schemes: ['Bearer']);
      const info2 = PushNotificationAuthenticationInfo(schemes: ['Bearer']);
      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
    });

    test('PushNotificationAuthenticationInfo toString works', () {
      const info = PushNotificationAuthenticationInfo(schemes: ['Bearer']);
      expect(info.toString(), contains('PushNotificationAuthenticationInfo'));
    });

    test('TaskPushNotificationConfig copyWith works', () {
      const config = PushNotificationConfig(url: 'https://example.com');
      const taskConfig = TaskPushNotificationConfig(
        taskId: 'task-1',
        pushNotificationConfig: config,
      );
      final TaskPushNotificationConfig copy = taskConfig.copyWith(
        taskId: 'task-2',
      );
      expect(copy.taskId, 'task-2');
    });

    test('TaskPushNotificationConfig operator == and hashCode', () {
      const config = PushNotificationConfig(url: 'https://example.com');
      const taskConfig1 = TaskPushNotificationConfig(
        taskId: 'task-1',
        pushNotificationConfig: config,
      );
      const taskConfig2 = TaskPushNotificationConfig(
        taskId: 'task-1',
        pushNotificationConfig: config,
      );
      expect(taskConfig1, equals(taskConfig2));
      expect(taskConfig1.hashCode, equals(taskConfig2.hashCode));
    });

    test('TaskPushNotificationConfig toString works', () {
      const config = PushNotificationConfig(url: 'https://example.com');
      const taskConfig = TaskPushNotificationConfig(
        taskId: 'task-1',
        pushNotificationConfig: config,
      );
      expect(taskConfig.toString(), contains('TaskPushNotificationConfig'));
    });
    test('AgentProvider can be serialized and deserialized', () {
      const provider = AgentProvider(
        organization: 'Test Org',
        url: 'https://example.com',
      );

      final Map<String, Object?> json = provider.toJson();
      final newProvider = AgentProvider.fromJson(json);

      expect(newProvider, equals(provider));
    });

    test('AgentProvider copyWith works', () {
      const provider = AgentProvider(
        organization: 'Test Org',
        url: 'https://example.com',
      );
      final AgentProvider copy = provider.copyWith(organization: 'New Org');
      expect(copy.organization, 'New Org');
      expect(copy.url, 'https://example.com');
    });

    test('AgentProvider toString works', () {
      const provider = AgentProvider(
        organization: 'Test Org',
        url: 'https://example.com',
      );
      expect(provider.toString(), contains('AgentProvider'));
    });
    test('TextPart operator == and hashCode', () {
      const part1 = TextPart(text: 'Hello');
      const part2 = TextPart(text: 'Hello');
      expect(part1, equals(part2));
      expect(part1.hashCode, equals(part2.hashCode));
    });

    test('FilePart copyWith, operator ==, hashCode, toString', () {
      const file = FileType.uri(uri: 'uri', mimeType: 'mime');
      const part1 = FilePart(file: file);
      const part2 = FilePart(file: file);

      expect(part1, equals(part2));
      expect(part1.hashCode, equals(part2.hashCode));
      expect(part1.toString(), contains('FilePart'));

      final FilePart copy = part1.copyWith(
        file: const FileType.uri(uri: 'new-uri', mimeType: 'mime'),
      );
      expect((copy.file as FileWithUri).uri, 'new-uri');
    });

    test('DataPart copyWith, operator ==, hashCode, toString', () {
      const part1 = DataPart(data: {'key': 'value'});
      const part2 = DataPart(data: {'key': 'value'});

      expect(part1, equals(part2));
      expect(part1.hashCode, equals(part2.hashCode));
      expect(part1.toString(), contains('DataPart'));

      final DataPart copy = part1.copyWith(data: {'key': 'new-value'});
      expect(copy.data['key'], 'new-value');
    });

    test('ListTasksParams copyWith without arguments works', () {
      const params = ListTasksParams(contextId: 'context-123');
      final ListTasksParams copy = params.copyWith();
      expect(copy.contextId, 'context-123');
      expect(copy.pageSize, 50);
    });
    test('Task copyWith works', () {
      const task = Task(
        id: '1',
        contextId: '2',
        status: TaskStatus(state: TaskState.working),
      );
      final Task copy = task.copyWith(contextId: '3');
      expect(copy.contextId, '3');
    });

    test('Task operator == and hashCode', () {
      const task1 = Task(
        id: '1',
        contextId: '2',
        status: TaskStatus(state: TaskState.working),
      );
      const task2 = Task(
        id: '1',
        contextId: '2',
        status: TaskStatus(state: TaskState.working),
      );
      expect(task1, equals(task2));
      expect(task1.hashCode, equals(task2.hashCode));
    });

    test('Task toString works', () {
      const task = Task(
        id: '1',
        contextId: '2',
        status: TaskStatus(state: TaskState.working),
      );
      expect(task.toString(), contains('Task'));
    });

    test('TaskStatus copyWith works', () {
      const status = TaskStatus(state: TaskState.working);
      final TaskStatus copy = status.copyWith(state: TaskState.completed);
      expect(copy.state, TaskState.completed);
    });

    test('TaskStatus operator == and hashCode', () {
      const status1 = TaskStatus(state: TaskState.working);
      const status2 = TaskStatus(state: TaskState.working);
      expect(status1, equals(status2));
      expect(status1.hashCode, equals(status2.hashCode));
    });

    test('TaskStatus toString works', () {
      const status = TaskStatus(state: TaskState.working);
      expect(status.toString(), contains('TaskStatus'));
    });

    test('Artifact copyWith works', () {
      const artifact = Artifact(artifactId: '1', parts: []);
      final Artifact copy = artifact.copyWith(name: 'New Name');
      expect(copy.name, 'New Name');
    });

    test('Artifact operator == and hashCode', () {
      const artifact1 = Artifact(artifactId: '1', parts: []);
      const artifact2 = Artifact(artifactId: '1', parts: []);
      expect(artifact1, equals(artifact2));
      expect(artifact1.hashCode, equals(artifact2.hashCode));
    });

    test('Artifact toString works', () {
      const artifact = Artifact(artifactId: '1', parts: []);
      expect(artifact.toString(), contains('Artifact'));
    });
    test('Message copyWith without arguments works', () {
      const message = Message(role: Role.user, parts: [], messageId: '12345');
      final Message copy = message.copyWith();
      expect(copy.role, Role.user);
      expect(copy.messageId, '12345');
    });
    test('Message operator == and hashCode', () {
      const message1 = Message(role: Role.user, parts: [], messageId: '12345');
      const message2 = Message(role: Role.user, parts: [], messageId: '12345');
      expect(message1, equals(message2));
      expect(message1.hashCode, equals(message2.hashCode));
    });
    test('ListTasksParams hashCode works', () {
      const params1 = ListTasksParams(contextId: 'context-123');
      const params2 = ListTasksParams(contextId: 'context-123');
      expect(params1.hashCode, equals(params2.hashCode));
    });
    test('AgentExtension copyWith without arguments works', () {
      const ext = AgentExtension(uri: 'uri-1', required: true);
      final AgentExtension copy = ext.copyWith();
      expect(copy.uri, 'uri-1');
      expect(copy.required, true);
    });

    test('AgentExtension hashCode works', () {
      const ext1 = AgentExtension(uri: 'uri-1', required: true);
      const ext2 = AgentExtension(uri: 'uri-1', required: true);
      expect(ext1.hashCode, equals(ext2.hashCode));
    });
    test('ListTasksResult copyWith without arguments works', () {
      const result = ListTasksResult(
        tasks: [],
        totalSize: 0,
        pageSize: 10,
        nextPageToken: '',
      );
      final ListTasksResult copy = result.copyWith();
      expect(copy.totalSize, 0);
      expect(copy.pageSize, 10);
    });

    test('ListTasksResult hashCode works', () {
      const result1 = ListTasksResult(
        tasks: [],
        totalSize: 0,
        pageSize: 10,
        nextPageToken: '',
      );
      const result2 = ListTasksResult(
        tasks: [],
        totalSize: 0,
        pageSize: 10,
        nextPageToken: '',
      );
      expect(result1.hashCode, equals(result2.hashCode));
    });
    test('AgentSkill copyWith without arguments works', () {
      const skill = AgentSkill(
        id: '1',
        name: 'Skill',
        description: 'Desc',
        tags: [],
      );
      final AgentSkill copy = skill.copyWith();
      expect(copy.id, '1');
      expect(copy.name, 'Skill');
    });

    test('AgentSkill hashCode works', () {
      const skill1 = AgentSkill(
        id: '1',
        name: 'Skill',
        description: 'Desc',
        tags: [],
      );
      const skill2 = AgentSkill(
        id: '1',
        name: 'Skill',
        description: 'Desc',
        tags: [],
      );
      expect(skill1.hashCode, equals(skill2.hashCode));
    });
    test('TextPart copyWith without arguments works', () {
      const part = TextPart(text: 'Hello');
      final TextPart copy = part.copyWith();
      expect(copy.text, 'Hello');
    });

    test('FilePart copyWith without arguments works', () {
      const file = FileType.uri(uri: 'uri', mimeType: 'mime');
      const part = FilePart(file: file);
      final FilePart copy = part.copyWith();
      expect(copy.file, equals(file));
    });

    test('FileWithBytes copyWith, operator ==, hashCode, toString', () {
      const file1 = FileWithBytes(bytes: 'bytes');
      const file2 = FileWithBytes(bytes: 'bytes');

      expect(file1, equals(file2));
      expect(file1.hashCode, equals(file2.hashCode));
      expect(file1.toString(), contains('FileWithBytes'));

      final FileWithBytes copy = file1.copyWith(bytes: 'new-bytes');
      expect(copy.bytes, 'new-bytes');

      final FileWithBytes copy2 = file1.copyWith();
      expect(copy2.bytes, 'bytes');
    });

    test('Part.fromJson throws on unknown kind', () {
      final json = {'kind': 'unknown'};
      expect(() => Part.fromJson(json), throwsArgumentError);
    });

    test('FileType.fromJson throws on unknown type', () {
      final json = {'type': 'unknown'};
      expect(() => FileType.fromJson(json), throwsArgumentError);
    });
    test('AgentInterface copyWith without arguments works', () {
      const interface = AgentInterface(
        url: 'url',
        transport: TransportProtocol.jsonrpc,
      );
      final AgentInterface copy = interface.copyWith();
      expect(copy.url, 'url');
      expect(copy.transport, TransportProtocol.jsonrpc);
    });

    test('AgentInterface hashCode works', () {
      const interface1 = AgentInterface(
        url: 'url',
        transport: TransportProtocol.jsonrpc,
      );
      const interface2 = AgentInterface(
        url: 'url',
        transport: TransportProtocol.jsonrpc,
      );
      expect(interface1.hashCode, equals(interface2.hashCode));
    });
    test('AgentProvider copyWith without arguments works', () {
      const provider = AgentProvider(
        organization: 'Org',
        url: 'https://example.com',
      );
      final AgentProvider copy = provider.copyWith();
      expect(copy.organization, 'Org');
      expect(copy.url, 'https://example.com');
    });

    test('AgentProvider hashCode works', () {
      const provider1 = AgentProvider(
        organization: 'Org',
        url: 'https://example.com',
      );
      const provider2 = AgentProvider(
        organization: 'Org',
        url: 'https://example.com',
      );
      expect(provider1.hashCode, equals(provider2.hashCode));
    });
  });
}
