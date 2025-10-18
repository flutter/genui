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
*/

void main() {
  test('sendRequest works', () async {
    final protocol = Protocol();
    final result = await protocol.sendRequest(requestText);
    expect(result, isNotNull);
  });
}
