import 'model.dart';

abstract class Backend {
  static Future<ToolCall?> sendRequest(
    UiSchemaDefinition schema,
    String request,
  ) async {
    // ignore: inference_failure_on_instance_creation
    await Future.delayed(const Duration(seconds: 1));

    // Implementation goes here
    return null;
  }
}
