import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'catalog.dart';
import 'jumping_dots.dart';
import 'thinking_verbs.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    required this.generator,
    required this.providerName,
    super.key,
  });

  final ContentGenerator generator;
  final String providerName;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GenUiManager _genUiManager;
  late final GenUiConversation _conversation;
  String? _latestSurfaceId;
  String? _statusMessage;
  String _thinkingVerb = 'Thinking';
  final TextEditingController _textController = TextEditingController();

  void _updateThinkingVerb() {
    if (_conversation.isProcessing.value) {
      setState(() {
        _thinkingVerb = thinkingVerbs[Random().nextInt(thinkingVerbs.length)];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _genUiManager = GenUiManager(catalog: ticTacToeCatalog);
    _conversation = GenUiConversation(
      contentGenerator: widget.generator,
      genUiManager: _genUiManager,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _onTextResponse,
      onError: (error) {
        debugPrint('Error: ${error.error}');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${error.error}')));
        }
      },
    );
    _conversation.isProcessing.addListener(_updateThinkingVerb);

    // Auto-start the game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _conversation.sendRequest(
          UserMessage([TextPart('Let\'s play Tic Tac Toe')]),
        ),
      );
    });
  }

  void _handleSurfaceAdded(SurfaceAdded surface) {
    if (!mounted) return;
    setState(() {
      _latestSurfaceId = surface.surfaceId;
    });
  }

  void _onTextResponse(String text) {
    if (!mounted) return;
    setState(() {
      _statusMessage = text;
    });
  }

  @override
  void dispose() {
    _conversation.isProcessing.removeListener(_updateThinkingVerb);
    _conversation.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tic Tac Toe with ${widget.providerName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _statusMessage = 'Restarting game...';
              });
              unawaited(
                _conversation.sendRequest(
                  UserMessage([TextPart('Start a new game')]),
                ),
              );
            },
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: _latestSurfaceId == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Starting game...'),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _conversation.isProcessing,
                    builder: (context, isProcessing, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              isProcessing
                                  ? _thinkingVerb
                                  : (_statusMessage ?? ''),
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (isProcessing) ...[
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: JumpingDots(
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.color ??
                                    Colors.black,
                                radius: 3,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _conversation.isProcessing,
                          builder: (context, isProcessing, child) {
                            return AbsorbPointer(
                              absorbing: isProcessing,
                              child: Opacity(
                                opacity: isProcessing ? 0.5 : 1.0,
                                child: child,
                              ),
                            );
                          },
                          child: GenUiSurface(
                            host: _genUiManager,
                            surfaceId: _latestSurfaceId!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
