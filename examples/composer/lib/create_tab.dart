// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'ai_client.dart';
import 'ai_client_transport.dart';
import 'surface_utils.dart';

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

      final List<A2uiMessage> parsedMessages = [];
      final StreamSubscription<A2uiMessage> messageSubscription = transport
          .incomingMessages
          .listen((message) {
            parsedMessages.add(message);
          });

      String? surfaceId;
      final StreamSubscription<SurfaceUpdate> surfaceSubscription = controller
          .surfaceUpdates
          .listen((update) {
            if (update is SurfaceAdded) {
              surfaceId = update.surfaceId;
            }
          });

      final message = ChatMessage.user(prompt);
      await conversation.sendRequest(message);

      // Yield twice to handle cases where message processing itself schedules
      // additional async work.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await messageSubscription.cancel();
      await surfaceSubscription.cancel();

      // Bail out if the widget was disposed while awaiting the AI response.
      if (_disposed) return;

      if (surfaceId != null && parsedMessages.isNotEmpty) {
        final Map<String, Map<String, Object?>> componentMap = {};
        for (final message in parsedMessages) {
          if (message is UpdateComponents) {
            final json = message.toJson();
            final components = json['components'];
            if (components is List) {
              mergeComponentsById(components, componentMap);
            }
          }
        }

        final componentsJson = const JsonEncoder.withIndent(
          '  ',
        ).convert(componentMap.values.toList());

        // Extract and merge data model from UpdateDataModel messages.
        Map<String, Object?> dataModel = {};
        for (final message in parsedMessages) {
          if (message is UpdateDataModel) {
            final json = message.toJson();
            final value = json['value'];
            if (value is Map<String, Object?>) {
              final path = json['path'] as String?;
              if (path == null || path == '/' || path.isEmpty) {
                dataModel = Map<String, Object?>.from(value);
              } else {
                setNestedValue(dataModel, path, value);
              }
            }
          }
        }

        final String? dataJson = dataModel.isNotEmpty
            ? const JsonEncoder.withIndent('  ').convert(dataModel)
            : null;

        widget.onSurfaceCreated(componentsJson, dataJson: dataJson);
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
