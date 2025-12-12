import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:dartantic_interface/dartantic_interface.dart';
import 'package:flutter/material.dart';
import 'package:genui_dartantic/genui_dartantic.dart';

import 'catalog.dart';
import 'game_page.dart';

enum AiProviderType { google, openai, anthropic }

class ProviderSelectionPage extends StatefulWidget {
  const ProviderSelectionPage({super.key});

  @override
  State<ProviderSelectionPage> createState() => _ProviderSelectionPageState();
}

class _ProviderSelectionPageState extends State<ProviderSelectionPage> {
  AiProviderType _selectedProvider = AiProviderType.google;

  // API key from dart-define
  static const _geminiApiKeyEnv = String.fromEnvironment('GEMINI_API_KEY');
  static final String? _geminiApiKey = _geminiApiKeyEnv.isEmpty
      ? null
      : _geminiApiKeyEnv;

  static const _openaiApiKeyEnv = String.fromEnvironment('OPENAI_API_KEY');

  static final String? _openaiApiKey = _openaiApiKeyEnv.isEmpty
      ? null
      : _openaiApiKeyEnv;

  static const _anthropicApiKeyEnv = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
  );

  static final String? _anthropicApiKey = _anthropicApiKeyEnv.isEmpty
      ? null
      : _anthropicApiKeyEnv;

  void _startGame() {
    final Provider provider;

    switch (_selectedProvider) {
      case AiProviderType.google:
        provider = dartantic.GoogleProvider(apiKey: _geminiApiKey);
        break;
      case AiProviderType.openai:
        provider = dartantic.OpenAIProvider(apiKey: _openaiApiKey);
        break;
      case AiProviderType.anthropic:
        provider = dartantic.AnthropicProvider(apiKey: _anthropicApiKey);
        break;
    }

    final generator = DartanticContentGenerator(
      provider: provider,
      catalog: ticTacToeCatalog,
      systemInstruction: _systemInstruction,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => GamePage(generator: generator)),
    );
  }

  static const _systemInstruction =
      'You are a Tic Tac Toe master. I want to play a game with you. '
      'I will play "X" and you will play "O". '
      'When I make a move, you should determine your move and then display the '
      'updated board using the "updateSurface" tool with the "TicTacToeBoard" component. '
      'The component expects a "cells" array of 9 strings. '
      'If I win, you lose. If you win, I lose. If the board is full, it is a draw.\n\n'
      'IMPORTANT: Do not include the JSON representation of the board (or "A user interface is shown...") in your text response. '
      'Only provide your conversational move commentary.\n\n'
      'CRITICAL: You MUST use the "updateSurface" tool to show the board. '
      'Do NOT use ASCII art or text to represent the board state. '
      'If you do not call the tool, the user cannot see the board.';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Tic Tac Toe Game')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButtonFormField<AiProviderType>(
            initialValue: _selectedProvider,
            decoration: const InputDecoration(labelText: 'AI Provider'),
            items: AiProviderType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
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
  );
}
