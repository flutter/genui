import 'model.dart';

abstract class Backend {
  static Future<ToolCall?> sendRequest(
    UiSchemaDefinition schema,
    String request,
  ) async {
    // Implementation goes here
    return null;
  }
}
