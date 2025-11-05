import 'package:a2a_dart/src/core/agent_card.dart';
import 'package:a2a_dart/src/core/agent_capabilities.dart';
import 'package:a2a_dart/src/core/message.dart';
import 'package:a2a_dart/src/core/part.dart';
import 'package:a2a_dart/src/core/task.dart';
import 'package:a2a_dart/src/core/security_scheme.dart';
import 'package:test/test.dart';

void main() {
  group('Data Models', () {
    test('AgentCard', () {
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

    test('Message', () {
      final message = Message(
        role: Role.user,
        parts: [Part.text(text: 'Hello, agent!')],
        messageId: '12345',
      );

      final json = message.toJson();
      final newMessage = Message.fromJson(json);

      expect(newMessage, equals(message));
    });

    test('Task', () {
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

    test('Part', () {
      final part = Part.text(text: 'Hello');

      final json = part.toJson();
      final newPart = Part.fromJson(json);

      expect(newPart, equals(part));
    });

    test('SecurityScheme', () {
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
