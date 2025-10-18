import 'package:custom_backend/main.dart';
import 'package:custom_backend/protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/*
Prompt for this code:

Update api.dart to make 'sendRequest works' passing.
Do not use mocking, instead make real request to Gemini API.
GEMINI_API_KEY environment variable is already set.
Add debug logs to help troubleshooting.
*/

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
  });

  for (final savedResponse in savedResponseAssets) {
    test('sendRequest works for $savedResponse', () async {
      final protocol = Protocol();
      final result = await protocol.sendRequest(
        requestText,
        savedResponse: savedResponse,
      );
      expect(result, isNotNull);
    });
  }
}
