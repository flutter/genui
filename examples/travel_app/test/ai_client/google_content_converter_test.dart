// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart'
    as google_ai;
import 'package:travel_app/src/ai_client/google_content_converter.dart';

void main() {
  group('GoogleContentConverter', () {
    test('converts interaction json to text', () {
      final converter = GoogleContentConverter();
      final interactionData = {'foo': 'bar'};
      final Uint8List bytes = utf8.encode(jsonEncode(interactionData));

      final message = ChatMessage(
        role: ChatMessageRole.user,
        parts: [
          DataPart(
            Uint8List.fromList(bytes),
            mimeType: 'application/vnd.genui.interaction+json',
          ),
        ],
      );

      final List<google_ai.Content> convertResult = converter.toGoogleAiContent(
        [message],
      );

      expect(convertResult, hasLength(1));
      final google_ai.Content content = convertResult.first;
      expect(content.role, 'user');
      expect(content.parts, hasLength(1));

      final google_ai.Part part = content.parts.first;
      expect(part.text, jsonEncode(interactionData));
      expect(part.inlineData, isNull);
    });

    test('converts other mime types to blobs', () {
      final converter = GoogleContentConverter();
      final bytes = Uint8List.fromList([1, 2, 3]);

      final message = ChatMessage(
        role: ChatMessageRole.user,
        parts: [DataPart(bytes, mimeType: 'image/png')],
      );

      final List<google_ai.Content> convertResult = converter.toGoogleAiContent(
        [message],
      );

      expect(convertResult, hasLength(1));
      final google_ai.Content content = convertResult.first;
      expect(content.role, 'user');
      expect(content.parts, hasLength(1));

      final google_ai.Part part = content.parts.first;
      expect(part.text, isNull);
      expect(part.inlineData, isNotNull);
      expect(part.inlineData!.mimeType, 'image/png');
      expect(part.inlineData!.data, bytes);
    });
  });
}
