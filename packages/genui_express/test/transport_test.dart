// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart' as genkit;
import 'package:genui/genui.dart';
import 'package:genui_express/genui_express.dart';

void main() {
  group('ExpressLocalTransport', () {
    late Catalog catalog;
    late genkit.Genkit ai;
    late genkit.ModelRef model;

    setUp(() {
      catalog = BasicCatalogItems.asNoAssetCatalog();
      ai = genkit.Genkit(isDevEnv: false);
      model = genkit.modelRef('local/mock-model');

      // Register a mock on-device model directly on Genkit
      ai.defineModel(
        name: 'local/mock-model',
        fn: (request, context) async {
          final responses = [
            'Here is a button for you:\n',
            '<a2ui>\n',
            'root = Button("Save", "saveAction")\n',
            '</a2ui>\n',
            'Hope that helps!\n',
          ];
          for (final chunk in responses) {
            context.sendChunk(
              genkit.ModelResponseChunk(
                content: [genkit.TextPart(text: chunk)],
              ),
            );
            // Yield thread control to allow stream processing
            await Future.delayed(const Duration(milliseconds: 1));
          }

          return genkit.ModelResponse(
            finishReason: genkit.FinishReason.stop,
            message: genkit.Message(
              role: genkit.Role.model,
              content: [genkit.TextPart(text: responses.join())],
            ),
          );
        },
      );
    });

    test('stream mixed text and compiled layout', () async {
      final transport = ExpressLocalTransport(
        ai: ai,
        model: model,
        catalog: catalog,
      );

      final List<String> textChunks = [];
      final List<A2uiMessage> messages = [];

      final textSub = transport.incomingText.listen(textChunks.add);
      final messageSub = transport.incomingMessages.listen(messages.add);

      await transport.sendRequest(ChatMessage.user('Hello'));

      // Allow event loops and microtasks to process streaming outcomes
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify conversational text streaming
      expect(textChunks, hasLength(2));
      expect(textChunks[0].trim(), 'Here is a button for you:');
      expect(textChunks[1].trim(), 'Hope that helps!');

      // Verify compiled layout messages and cast to subtypes
      expect(messages, hasLength(2));

      expect(messages[0], isA<CreateSurface>());
      final createMsg = messages[0] as CreateSurface;
      expect(createMsg.surfaceId, startsWith('surface_'));

      expect(messages[1], isA<UpdateComponents>());
      final updateMsg = messages[1] as UpdateComponents;
      expect(updateMsg.components, hasLength(2));

      final buttonComp = updateMsg.components.firstWhere((c) => c.id == 'root');
      expect(buttonComp.type, 'Button');
      expect(buttonComp.properties['action'], {
        'event': {'name': 'saveAction', 'context': const <String, dynamic>{}},
      });

      await textSub.cancel();
      await messageSub.cancel();
      transport.dispose();
    });
  });
}
