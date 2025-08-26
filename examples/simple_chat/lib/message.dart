import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

class MessageViewController {
  MessageViewController({this.text, this.surfaceId})
    : assert((surfaceId == null) != (text == null));

  final String? text;
  final String? surfaceId;
}

class MessageView extends StatefulWidget {
  const MessageView(this.controller, this.builder, {super.key});

  final MessageViewController controller;
  final SurfaceBuilder builder;

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
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
