// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'ai_client.dart';
import 'ai_client_transport.dart';

/// The Create tab. Shows a prompt input and, upon submission, generates a UI
/// surface via AI and transitions to the surface editor.
class CreateTab extends StatefulWidget {
  const CreateTab({super.key, required this.onSurfaceCreated});

  final void Function(String componentsJson, {String? dataJson})
  onSurfaceCreated;

  @override
  State<CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends State<CreateTab> {
  static const String _examplePrompt = 'a weather card';

  final TextEditingController _promptController = TextEditingController();
  final Logger _logger = Logger('CreateTab');
  late final FocusNode _focusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (!_isGenerating &&
          event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _generate();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );

  bool _isGenerating = false;
  bool _disposed = false;
  String? _error;

  /// Resources for the current in-flight request, stored so they can be
  /// disposed if the widget is torn down mid-generation.
  AiClientTransport? _activeTransport;
  SurfaceController? _activeController;
  Conversation? _activeConversation;

  Future<void> _generate() async {
    final String prompt = _promptController.text.trim().isEmpty
        ? _examplePrompt
        : _promptController.text.trim();

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final AiClient aiClient = DartanticAiClient();
      final transport = _activeTransport = AiClientTransport(
        aiClient: aiClient,
      );

      final Catalog catalog = BasicCatalogItems.asCatalog();
      final controller = _activeController = SurfaceController(
        catalogs: [catalog],
      );

      final conversation = _activeConversation = Conversation(
        controller: controller,
        transport: transport,
      );

      final promptBuilder = PromptBuilder.chat(
        catalog: catalog,
        systemPromptFragments: [
          'You are a UI generator. The user will describe a UI they want. '
              'Generate a single A2UI surface that matches their description. '
              'Be creative and use appropriate components from the catalog.',
        ],
      );
      transport.addSystemMessage(promptBuilder.systemPromptJoined());

      final message = ChatMessage.user(prompt);
      await conversation.sendRequest(message);

      if (_disposed) return;

      final surfaceId = controller.activeSurfaceIds.firstOrNull;
      if (surfaceId != null) {
        final context = controller.contextFor(surfaceId);
        final definition = context.definition.value;
        if (definition != null) {
          final componentsJson = const JsonEncoder.withIndent('  ').convert(
            definition.components.values.map((c) => c.toJson()).toList(),
          );

          final dataModel = context.dataModel;
          final data = dataModel.getValue<Object?>(DataPath.root);
          final String? dataJson =
              data is Map<String, Object?> && data.isNotEmpty
              ? const JsonEncoder.withIndent('  ').convert(data)
              : null;

          widget.onSurfaceCreated(componentsJson, dataJson: dataJson);
        } else {
          setState(() {
            _error = 'Surface was created but has no definition.';
          });
        }
      } else {
        setState(() {
          _error =
              'No surface was generated. The AI may not have produced '
              'valid A2UI output. Try a different description.';
        });
      }
    } catch (e, stack) {
      _logger.severe('Error generating surface', e, stack);
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      _disposeActiveResources();
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _disposeActiveResources() {
    _activeConversation?.dispose();
    _activeController?.dispose();
    _activeTransport?.dispose();
    _activeConversation = null;
    _activeController = null;
    _activeTransport = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _disposeActiveResources();
    _focusNode.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What would you like to build?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _promptController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Describe a UI... (e.g. "$_examplePrompt")',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isGenerating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _generate,
                        ),
                ),
                enabled: !_isGenerating,
                maxLines: 3,
                minLines: 1,
              ),
              if (_isGenerating) ...[
                const SizedBox(height: 16),
                Text(
                  'Generating surface...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
