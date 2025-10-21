// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:http/http.dart' as http;

import '../debug_utils.dart';
import 'model.dart';

// mode='ANY':
// The model is constrained to always predict a function call and
// guarantees function schema adherence.
// https://ai.google.dev/gemini-api/docs/function-calling?example=meeting#rest_2

abstract class Backend {
  static Future<ToolCall?> sendRequest(
    List<FunctionDeclaration> tools,
    String request, {
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

    final response = jsonDecode(rawResponse);
    debugSaveToFileObject('full-response', response);
    final toolCallPart = response['candidates'][0]['content']['parts'][0];
    final functionCall = toolCallPart['functionCall'];
    if (functionCall == null) return null;
    return ToolCall.fromJson(functionCall as JsonMap);
  }

  static Future<String> _getSavedRawResponse(String savedResponse) async =>
      await rootBundle.loadString(savedResponse);

  static Future<String?> _getRawResponseFromApi(
    List<FunctionDeclaration> tools,
    String request,
  ) async {
    debugSaveToFileObject('tools', tools);

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
        {'function_declarations': tools.map((e) => e.toJson()).toList()},
      ],
      'tool_config': {
        'function_calling_config': {
          'mode': 'ANY',
          'allowed_function_names': tools.map((e) => e.name).toList(),
        },
      },
    });

    final response = await http.post(
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
