import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

class ChatMessageController {
  ChatMessageController({this.text, this.surfaceId})
    : assert((surfaceId == null) != (text == null));

  final String? text;
  final String? surfaceId;
}

class ChatMessage extends StatefulWidget {
  const ChatMessage(this.controller, {super.key, required this.builder});

  final ChatMessageController controller;
  final SurfaceBuilder builder;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  @override
  Widget build(BuildContext context) {
    final surfaceId = widget.controller.surfaceId;

    if (surfaceId == null) return Text(widget.controller.text ?? '');

    return GenUiSurface(
      builder: widget.builder,
      surfaceId: surfaceId,
      onEvent: (event) {},
    );
  }
}
