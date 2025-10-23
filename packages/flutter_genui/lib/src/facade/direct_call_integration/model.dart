import '../../model/a2ui_message.dart';

sealed class Part {
  const Part();

  factory Part.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'ToolCall':
        return ToolCall.fromJson(json);

      default:
        throw ArgumentError('Invalid Part type: ${json["type"]}');
    }
  }

  Map<String, dynamic> toJson();
}

class ToolCall extends Part {
  final dynamic args;
  final String name;

  const ToolCall({required this.args, required this.name});

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      ToolCall(args: json['args'], name: json['name'] as String);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ToolCall',
    'args': args,
    'name': name,
  };
}

/// Declaration to be provided to the LLM about a function/tool.
class FunctionDeclaration {
  final String description;
  final String name;
  final dynamic parameters;

  FunctionDeclaration({
    required this.description,
    required this.name,
    this.parameters,
  });

  factory FunctionDeclaration.fromJson(Map<String, dynamic> json) =>
      FunctionDeclaration(
        description: json['description'] as String,
        name: json['name'] as String,
        parameters: json['parameters'],
      );

  Map<String, dynamic> toJson() => {
    'description': description,
    'name': name,
    'parameters': parameters,
  };
}

class ParsedToolCall {
  final List<A2uiMessage> messages;
  final String surfaceId;

  ParsedToolCall({required this.messages, required this.surfaceId});
}
