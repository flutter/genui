// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;

import 'debug_utils.dart';

// mode='ANY':
// The model is constrained to always predict a function call and
// guarantees function schema adherence.
// https://ai.google.dev/gemini-api/docs/function-calling?example=meeting#rest_2

abstract class GeminiClient {
  static Future<ToolCall?> sendRequest({
    required List<GenUiFunctionDeclaration> tools,
    required String request,
    required String? savedResponse,
  }) async {
    late final String? rawResponse;
    if (savedResponse == null) {
      rawResponse = await _getRawResponseFromApi(tools, request);
    } else {
      rawResponse = await _getSavedRawResponse(savedResponse);
    }

    if (rawResponse == null) {
      return null;
    }

    final response = jsonDecode(rawResponse) as JsonMap;

    Map<String, Object?> extractToolCallPart(JsonMap response) {
      final candidates = response['candidates'] as List<Object?>;
      final firstCandidate = candidates.first as Map<String, Object?>;
      final content = firstCandidate['content'] as Map<String, Object?>;
      final parts = content['parts'] as List<Object?>;
      return parts.first as Map<String, Object?>;
    }

    debugSaveToFileObject('full-response', response);
    final Map<String, Object?> toolCallPart = extractToolCallPart(response);
    final Object? functionCall = toolCallPart['functionCall'];
    if (functionCall == null) return null;
    return ToolCall.fromJson(functionCall as JsonMap);
  }

  static Future<String> _getSavedRawResponse(String savedResponse) async =>
      await rootBundle.loadString(savedResponse);

  static Future<String?> _getRawResponseFromApi(
    List<GenUiFunctionDeclaration> tools,
    String request,
  ) async {
    debugSaveToFileObject('tools', tools);

    final String? apiKey = Platform.environment['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY environment variable not set.');
    }

    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey',
    );

    final String body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': request},
          ],
        },
      ],
      'tools': [
        {'function_declarations': tools.map((e) => e.toJson()).toList()},
      ],
      'tool_config': {
        'function_calling_config': {
          'mode': 'ANY',
          'allowed_function_names': tools.map((e) => e.name).toList(),
        },
      },
    });

    final http.Response response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      debugSaveToFileObject('response-body', response.body);
      return response.body;
    } else {
      throw Exception('Failed to send request: ${response.body}');
    }
  }
}
