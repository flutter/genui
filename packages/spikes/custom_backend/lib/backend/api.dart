import 'model.dart';

/*
Prompt to create this code:
Implement sendRequest to send request to gemini with enforced schema.
Use direct REST API calls with http package as described here:
https://ai.google.dev/gemini-api/docs/function-calling?example=meeting#rest_2
*/

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
