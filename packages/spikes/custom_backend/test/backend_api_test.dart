import 'package:custom_backend/main.dart';
import 'package:custom_backend/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

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
