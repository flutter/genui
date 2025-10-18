import 'model.dart';

abstract class Backend {
  static Future<ToolCall?> sendRequest(
    UiSchemaDefinition schema,
    String request,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    // Implementation goes here
    return null;
  }
}
