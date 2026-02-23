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

/// The Create tab. Shows a prompt input and, upon submission, generates a UI
/// surface via AI and transitions to the surface editor.
class CreateTab extends StatefulWidget {
  const CreateTab({super.key, required this.onSurfaceCreated});

  /// Called with the components JSON and optional data model JSON
  /// when a surface is successfully generated.
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
  String? _error;

  Future<void> _generate() async {
    final String prompt = _promptController.text.trim().isEmpty
        ? _examplePrompt
        : _promptController.text.trim();

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    AiClientTransport? transport;

    try {
      final AiClient aiClient = DartanticAiClient();
      transport = AiClientTransport(aiClient: aiClient);

      final Catalog catalog = BasicCatalogItems.asCatalog();
      final SurfaceController controller = SurfaceController(
        catalogs: [catalog],
      );

      final Conversation conversation = Conversation(
        controller: controller,
        transport: transport,
      );

      // Set up system prompt
      final promptBuilder = PromptBuilder.chat(
        catalog: catalog,
        instructions:
            'You are a UI generator. The user will describe a UI they want. '
            'Generate a single A2UI surface that matches their description. '
            'Be creative and use appropriate components from the catalog.',
      );
      transport.addSystemMessage(promptBuilder.systemPrompt);

      // Capture parsed A2UI messages (these are validated and complete)
      final List<A2uiMessage> parsedMessages = [];
      final StreamSubscription<A2uiMessage> messageSub = transport
          .incomingMessages
          .listen((message) {
            parsedMessages.add(message);
          });

      // Wait for surface to be created
      String? surfaceId;
      final StreamSubscription<SurfaceUpdate> surfaceSub = controller
          .surfaceUpdates
          .listen((update) {
            if (update is SurfaceAdded) {
              surfaceId = update.surfaceId;
            }
          });

      // Send the request
      final message = ChatMessage.user(prompt);
      await conversation.sendRequest(message);

      // Wait a moment for any remaining events to be processed
      await Future<void>.delayed(const Duration(milliseconds: 500));

      await messageSub.cancel();
      await surfaceSub.cancel();

      if (surfaceId != null && parsedMessages.isNotEmpty) {
        // Consolidate all UpdateComponents messages into a single
        // components array, merging by component ID (later overrides earlier).
        final Map<String, Map<String, dynamic>> componentMap = {};
        for (final msg in parsedMessages) {
          if (msg is UpdateComponents) {
            final json = msg.toJson();
            final components = json['components'];
            if (components is List) {
              for (final comp in components) {
                if (comp is Map<String, dynamic> && comp['id'] != null) {
                  componentMap[comp['id'] as String] = comp;
                }
              }
            }
          }
        }

        // Output just the final components array
        final consolidatedComponents = componentMap.values.toList();
        final componentsJson = const JsonEncoder.withIndent(
          '  ',
        ).convert(consolidatedComponents);

        // Also extract and merge data model from UpdateDataModel messages
        Map<String, dynamic> dataModel = {};
        for (final msg in parsedMessages) {
          if (msg is UpdateDataModel) {
            final json = msg.toJson();
            final value = json['value'];
            if (value is Map<String, dynamic>) {
              final path = json['path'] as String?;
              if (path == null || path == '/' || path.isEmpty) {
                dataModel = Map<String, dynamic>.from(value);
              } else {
                // Set nested value at the specified path
                final segments = path
                    .split('/')
                    .where((s) => s.isNotEmpty)
                    .toList();
                Map<String, dynamic> current = dataModel;
                for (int i = 0; i < segments.length - 1; i++) {
                  current.putIfAbsent(segments[i], () => <String, dynamic>{});
                  current = current[segments[i]] as Map<String, dynamic>;
                }
                current[segments.last] = value;
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

      conversation.dispose();
      controller.dispose();
    } catch (e, stack) {
      _logger.severe('Error generating surface', e, stack);
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      transport?.dispose();
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
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
