// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:travel_app/src/ai_client/google_generative_ai_client.dart';
import 'package:travel_app/src/ai_client/google_generative_service_interface.dart';

void main() {
  group('GoogleGenerativeAiClient', () {
    late FakeGoogleGenerativeService fakeService;
    late GoogleGenerativeAiClient client;

    setUp(() {
      fakeService = FakeGoogleGenerativeService();
      client = GoogleGenerativeAiClient(
        catalog: const Catalog({}), // Empty catalog for testing
        apiKey: 'test-api-key',
        serviceFactory: ({required configuration}) => fakeService,
      );
    });

    test('sendRequest includes clientDataModel in prompt', () async {
      final Map<String, Object> clientData = {'theme': 'dark', 'userId': 123};
      final message = ChatMessage(
        role: ChatMessageRole.user,
        parts: [const TextPart('Hello')],
      );

      // Stub the response to avoid null errors
      fakeService.responseToReturn = google_ai.GenerateContentResponse(
        candidates: [
          google_ai.Candidate(
            content: google_ai.Content(
              parts: [google_ai.Part(text: 'Response')],
            ),
          ),
        ],
      );

      await client.sendRequest(message, clientDataModel: clientData);

      final google_ai.GenerateContentRequest? capturedRequest =
          fakeService.capturedRequest;
      expect(capturedRequest, isNotNull);

      // Verify that the clientDataModel is included in the request contents
      var foundClientData = false;
      for (final google_ai.Content content in capturedRequest!.contents) {
        for (final google_ai.Part part in content.parts) {
          if (part.text != null && part.text!.contains('Client Data Model:')) {
            expect(part.text, contains('"theme": "dark"'));
            expect(part.text, contains('"userId": 123'));
            foundClientData = true;
          }
        }
      }
      expect(
        foundClientData,
        isTrue,
        reason: 'Client Data Model not found in prompt',
      );
    });
  });
}

class FakeGoogleGenerativeService implements GoogleGenerativeServiceInterface {
  google_ai.GenerateContentRequest? capturedRequest;
  google_ai.GenerateContentResponse? responseToReturn;

  @override
  Future<google_ai.GenerateContentResponse> generateContent(
    google_ai.GenerateContentRequest request,
  ) async {
    capturedRequest = request;
    return responseToReturn ?? google_ai.GenerateContentResponse();
  }

  @override
  void close() {}
}
