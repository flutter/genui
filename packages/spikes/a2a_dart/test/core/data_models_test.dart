import 'package:a2a_dart/src/core/agent_card.dart';
import 'package:a2a_dart/src/core/agent_capabilities.dart';
import 'package:a2a_dart/src/core/message.dart';
import 'package:a2a_dart/src/core/part.dart';
import 'package:a2a_dart/src/core/task.dart';
import 'package:a2a_dart/src/core/security_scheme.dart';
import 'package:test/test.dart';

void main() {
  group('Data Models', () {
    test('AgentCard can be serialized and deserialized', () {
      final agentCard = AgentCard(
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

      final json = agentCard.toJson();
      final newAgentCard = AgentCard.fromJson(json);

      expect(newAgentCard, equals(agentCard));
    });

    test(
        'AgentCard with optional fields null can be serialized and deserialized',
        () {
      final agentCard = AgentCard(
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

      final json = agentCard.toJson();
      final newAgentCard = AgentCard.fromJson(json);

      expect(newAgentCard, equals(agentCard));
    });

    test('Message can be serialized and deserialized', () {
      final message = Message(
        role: Role.user,
        parts: [Part.text(text: 'Hello, agent!')],
        messageId: '12345',
      );

      final json = message.toJson();
      final newMessage = Message.fromJson(json);

      expect(newMessage, equals(message));
    });

    test('Message with empty parts can be serialized and deserialized', () {
      final message = Message(
        role: Role.user,
        parts: [],
        messageId: '12345',
      );

      final json = message.toJson();
      final newMessage = Message.fromJson(json);

      expect(newMessage, equals(message));
    });

    test('Message with multiple parts can be serialized and deserialized', () {
      final message = Message(
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

      final json = message.toJson();
      final newMessage = Message.fromJson(json);

      expect(newMessage, equals(message));
    });

    test('Task can be serialized and deserialized', () {
      final task = Task(
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

      final json = task.toJson();
      final newTask = Task.fromJson(json);

      expect(newTask, equals(task));
    });

    test('Task with optional fields null can be serialized and deserialized',
        () {
      final task = Task(
        id: 'task-123',
        contextId: 'context-456',
        status: TaskStatus(state: TaskState.working),
      );

      final json = task.toJson();
      final newTask = Task.fromJson(json);

      expect(newTask, equals(task));
    });

    test('Part can be serialized and deserialized', () {
      final partText = Part.text(text: 'Hello');
      final jsonText = partText.toJson();
      final newPartText = Part.fromJson(jsonText);
      expect(newPartText, equals(partText));

      final partFileUri = Part.file(
        file: FileType.uri(
          uri: 'file:///path/to/file.txt',
          mimeType: 'text/plain',
        ),
      );
      final jsonFileUri = partFileUri.toJson();
      final newPartFileUri = Part.fromJson(jsonFileUri);
      expect(newPartFileUri, equals(partFileUri));

      final partFileBytes = Part.file(
        file: FileType.bytes(
          bytes: 'aGVsbG8=', // base64 for "hello"
          name: 'hello.txt',
        ),
      );
      final jsonFileBytes = partFileBytes.toJson();
      final newPartFileBytes = Part.fromJson(jsonFileBytes);
      expect(newPartFileBytes, equals(partFileBytes));

      final partData = Part.data(data: {'key': 'value'});
      final jsonData = partData.toJson();
      final newPartData = Part.fromJson(jsonData);
      expect(newPartData, equals(partData));
    });

    test('SecurityScheme can be serialized and deserialized', () {
      final securityScheme = SecurityScheme.apiKey(
        name: 'test_key',
        in_: 'header',
      );

      final json = securityScheme.toJson();
      final newSecurityScheme = SecurityScheme.fromJson(json);

      expect(newSecurityScheme, equals(securityScheme));
    });
  });
}
