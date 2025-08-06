// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

typedef ChatBoxCallback = void Function(String input);

typedef ChatBoxBuilder = Widget Function(ChatBoxController controller);

Widget defaultChatBoxBuilder(ChatBoxController controller) =>
    ChatBox(controller);

class ChatBoxController {
  ChatBoxController(this.onInput);

  /// The chat box will stop taking input after [stopped] is completed.
  final stopped = Completer<void>();

  /// Is invoked when the user submits input.
  ///
  /// User can submit input multiple times, so this callback
  /// should be able to handle multiple invocations.
  final void Function(String input) onInput;

  /// If true, the user will see a progress indicator.
  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(true);

  void dispose() {
    stopped.complete();
    isProcessing.dispose();
  }
}

class ChatBox extends StatefulWidget {
  ChatBox(
    this.controller, {
    super.key,
    this.borderRadius = 25.0,
    this.hintText = 'Ask me anything',
  });

  final ChatBoxController controller;
  final double borderRadius;
  final String hintText;

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send),
          onPressed: _submit,
        ),
      ),
      maxLines: null, // Allows for multi-line input
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.send,
      onSubmitted: (String value) => _submit(),
    );
  }

  void _submit() {
    final inputText = _controller.text.trim();
    _focusNode.unfocus();
    widget.controller.onInput(inputText);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
