// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';

/// Walks through the agent workflow: register catalogs, negotiate with a
/// renderer, prompt a model, then parse and validate what it returns.
void main() {
  // 1. At startup, register every catalog the agent supports. Transformers
  //    trim a catalog down to what this agent is willing to generate.
  final generator = A2uiGenerator(
    catalogs: [
      CatalogConfig(
        MinimalCatalog(),
        transformers: [
          ComponentPruningTransformer(const ['Column', 'Text', 'Button']),
        ],
      ),
    ],
    examples: {
      'A greeting with a dismiss button': _greetingExample(),
    },
  );

  // 2. Per request, negotiate against what the renderer says it can render.
  final capabilities = A2uiRendererCapabilities.fromJson({
    'v0.9': {
      'supportedCatalogIds': [MinimalCatalog().id],
    },
  });
  final A2uiRequestProcessor processor = generator.createProcessor(
    capabilities,
  );

  // 3. Prepend the prompt snippet to the agent's own system instructions.
  print('--- system prompt snippet (truncated) ---');
  print(processor.promptSnippet.split('\n').take(12).join('\n'));

  // 4. Parse and validate the model's response.
  final List<ResponsePart> parts = processor.parseResponse(_fakeLlmOutput);

  // 5. Deliver the payloads to the renderer.
  print('\n--- parsed response ---');
  for (final part in parts) {
    switch (part) {
      case TextPart(text: final String text):
        print('text: $text');
      case A2uiPart(a2ui: final List<AgentToRendererMessage> messages):
        for (final message in messages) {
          print('a2ui: ${message.toJson()}');
        }
    }
  }

  // The same catalogs also drive the compact Express format, where the model
  // writes positional statements instead of JSON.
  final expressProcessor = A2uiRequestProcessor(
    catalogs: processor.activeCatalogs,
    formatFactory: const ExpressFormatFactory(),
  );
  print('\n--- express ---');
  for (final ResponsePart part
      in expressProcessor.parseResponse(_fakeExpressOutput)) {
    if (part is A2uiPart) {
      for (final AgentToRendererMessage message in part.a2ui) {
        print('a2ui: ${message.toJson()}');
      }
    }
  }
}

List<AgentToRendererMessage> _greetingExample() => [
  CreateSurfaceMessage(surfaceId: 'greeting', catalogId: MinimalCatalog().id),
  UpdateComponentsMessage(
    surfaceId: 'greeting',
    components: [
      {
        'id': 'root',
        'component': 'Column',
        'children': ['title'],
      },
      {'id': 'title', 'component': 'Text', 'text': 'Hello!', 'variant': 'h1'},
    ],
  ),
];

const String _fakeLlmOutput = '''
Here is the panel you asked for.
<a2ui-json>
[
  {
    "version": "v0.9",
    "createSurface": {"surfaceId": "s1", "catalogId": "https://a2ui.org/specification/v0_9/catalogs/minimal/minimal_catalog.json"}
  },
  {
    "version": "v0.9",
    "updateComponents": {
      "surfaceId": "s1",
      "components": [
        {"id": "root", "component": "Column", "children": ["greeting"]},
        {"id": "greeting", "component": "Text", "text": "Good morning"}
      ]
    }
  }
]
</a2ui-json>
Let me know if you want a different layout.
''';

const String _fakeExpressOutput = '''
<a2ui-express>
surface("s2")
root = Column([greeting, dismiss])
greeting = Text("Good morning", "h1")
dismiss = Button(Text("Dismiss"), Event("dismiss"))
</a2ui-express>
''';
