// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:flutter/material.dart';
import 'package:genui_dartantic/genui_dartantic.dart';

import 'catalog.dart';
import 'game_page.dart';

enum AiProviderType {
  google,
  openai,
  anthropic;

  String get displayName => switch (this) {
    AiProviderType.google => 'Google',
    AiProviderType.openai => 'OpenAI',
    AiProviderType.anthropic => 'Anthropic',
  };

  String get modelName => switch (this) {
    AiProviderType.google => 'gemini-2.5-flash',
    AiProviderType.openai => 'gpt-5-mini',
    AiProviderType.anthropic => 'claude-haiku-4-5',
  };
}

class ProviderSelectionPage extends StatefulWidget {
  const ProviderSelectionPage({super.key});

  @override
  State<ProviderSelectionPage> createState() => _ProviderSelectionPageState();
}

class _ProviderSelectionPageState extends State<ProviderSelectionPage> {
  AiProviderType _selectedProvider = AiProviderType.google;

  // API key from dart-define
  static const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _anthropicApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  void _startGame() {
    final dartantic.Provider provider = switch (_selectedProvider) {
      AiProviderType.google => dartantic.GoogleProvider(apiKey: _geminiApiKey),
      AiProviderType.openai => dartantic.OpenAIResponsesProvider(
        apiKey: _openaiApiKey,
      ),
      AiProviderType.anthropic => dartantic.AnthropicProvider(
        apiKey: _anthropicApiKey,
      ),
    };

    final generator = DartanticContentGenerator(
      provider: provider,
      modelName: _selectedProvider.modelName,
      catalog: ticTacToeCatalog,
      systemInstruction: _systemInstruction,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GamePage(generator: generator, providerName: provider.displayName),
      ),
    );
  }

  static const _systemInstruction = '''
You are a Tic Tac Toe master. The user plays "X" and you play "O".

<output_verbosity_spec>
- Keep move commentary to 1-2 sentences.
- Do not rephrase the game state or user's move.
- Do not include JSON representations or "A user interface is shown..." text.
</output_verbosity_spec>

<tool_usage_rules>
- You MUST call both tools to display the board—never use ASCII art or text representations.
- Parallelize these two calls:
  1. "updateSurface" — create a "TicTacToeBoard" component (ID: "board") with a "cells" array of 9 strings.
  2. "beginRendering" — set the surface root to that ID.
- If you do not call these tools, the user cannot see the board.
</tool_usage_rules>

<game_rules>
- If the user wins, you lose. If you win, the user loses. Full board with no winner is a draw.
</game_rules>
''';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Tic Tac Toe Game')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AiProviderType>(
                initialValue: _selectedProvider,
                decoration: const InputDecoration(labelText: 'AI Provider'),
                items: AiProviderType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedProvider = value);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startGame,
                  child: const Text('Start Game'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
