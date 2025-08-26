import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

class ChatMessageController {
  ChatMessageController({this.text, this.surfaceId})
    : assert((surfaceId == null) != (text == null));

  final String? text;
  final String? surfaceId;
}

class ChatMessage extends StatefulWidget {
  const ChatMessage(this.controller, {super.key, required this.uiAgent});

  final ChatMessageController controller;
  final UiAgent uiAgent;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  late final ValueNotifier<UiDefinition?>? _definition;

  @override
  void didUpdateWidget(covariant ChatMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.surfaceId == widget.controller.surfaceId &&
        oldWidget.controller.text == widget.controller.text &&
        oldWidget.uiAgent == widget.uiAgent) {
      return;
    }
    _init();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final surfaceId = widget.controller.surfaceId;
    if (surfaceId == null) return;
    _definition = widget.uiAgent.surface(surfaceId);
  }

  @override
  Widget build(BuildContext context) {
    final surfaceId = widget.controller.surfaceId;

    if (surfaceId == null) return Text(widget.controller.text ?? '');

    return GenUiSurface(
      manager: manager,
      surfaceId: surfaceId,
      onEvent: onEvent,
    );
  }
}
