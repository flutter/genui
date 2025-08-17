// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

class ChatMessageController {
  ChatMessageController({this.text, this.genUiResponse});

  final String? text;
  final GenUiResponse? genUiResponse;

  UserSelection? selection;
}

class ChatMessage extends StatefulWidget {
  const ChatMessage(this.controller, {super.key, required this.onSubmitted});

  final ChatMessageController controller;
  final ValueChanged<UserSelection> onSubmitted;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  @override
  Widget build(BuildContext context) {
    final builder = widget.controller.genUiResponse?.chatMessage;
    if (builder == null) {
      return Text(widget.controller.text ?? '');
    }

    return builder(
      selection: widget.controller.selection,
      context: context,
      onChanged: (selection) =>
          setState(() => widget.controller.selection = selection),
      onSubmitted: widget.onSubmitted,
    );
  }
}
