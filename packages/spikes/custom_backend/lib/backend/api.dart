// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';

import 'package:flutter_genui/flutter_genui.dart';
import 'package:http/http.dart' as http;

import '../debug_utils.dart';
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
    final apiKey = Platform.environment['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY environment variable not set.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': request},
          ],
        },
      ],
      'tools': [
        {'function_declarations': schema.tools.map((e) => e.toJson()).toList()},
      ],
      'tool_config': {
        'function_calling_config': {
          'mode': 'ANY',
          'allowed_function_names': schema.tools.map((e) => e.name).toList(),
        },
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      debugSaveToFileObject('full-response', responseBody);
      final toolCallPart = responseBody['candidates'][0]['content']['parts'][0];
      if (toolCallPart['functionCall'] != null) {
        return ToolCall.fromJson(toolCallPart['functionCall'] as JsonMap);
      }
    } else {
      print('Failed to send request: ${response.body}');
      throw Exception('Failed to send request: ${response.body}');
    }

    return null;
  }
}
