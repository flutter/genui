import 'package:genai_primitives/genai_primitives.dart';
import 'package:test/test.dart';

void main() {
  group('GenAI Primitives Smoke Test', () {
    test('Can create TextPart', () {
      final part = const TextPart('hello');
      expect(part.text, equals('hello'));
    });

    test('Can create ChatMessage', () {
      final message = ChatMessage.user('hello');
      expect(message.role, equals(ChatMessageRole.user));
      expect(message.parts.length, equals(1));
      expect((message.parts.first as TextPart).text, equals('hello'));
    });

    test('Can create ToolDefinition', () {
      final ToolDefinition<Object> tool = ToolDefinition(
        name: 'test_tool',
        description: 'A test tool',
      );
      expect(tool.name, equals('test_tool'));
      expect(tool.description, equals('A test tool'));
      expect(tool.inputSchema.value, isNotNull);
    });

    test('Can create ToolPart.call', () {
      final part = const ToolPart.call(
        id: '1',
        name: 'myTool',
        arguments: {'x': 1},
      );
      expect(part.kind, equals(ToolPartKind.call));
      expect(part.id, equals('1'));
      expect(part.name, equals('myTool'));
      expect(part.arguments, equals({'x': 1}));
    });

    test('Can create ToolPart.result', () {
      final part = const ToolPart.result(
        id: '1',
        name: 'myTool',
        result: 'success',
      );
      expect(part.kind, equals(ToolPartKind.result));
      expect(part.id, equals('1'));
      expect(part.name, equals('myTool'));
      expect(part.result, equals('success'));
    });
  });
}
