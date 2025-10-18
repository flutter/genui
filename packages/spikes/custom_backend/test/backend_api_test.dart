import 'dart:convert';
import 'dart:io';

import 'package:custom_backend/backend/api.dart';
import 'package:custom_backend/main.dart';
import 'package:custom_backend/protocol.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/*
Prompt for this code:

Update api.dart to make 'sendRequest works' passing.
Do not use mocking, instead make real request to Gemini API.
GEMINI_API_KEY environment variable is already set.
Add debug logs to help troubleshooting.
*/

void main() {
  test('sendRequest works', () async {
    final protocol = Protocol();
    final result = await protocol.sendRequest(requestText);
    expect(result, isNotNull);
  });
}
