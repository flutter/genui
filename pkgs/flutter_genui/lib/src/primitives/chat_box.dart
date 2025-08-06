// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

typedef ChatBoxCallback = void Function(String input);

class ChatBox extends StatefulWidget {
  ChatBox(
    this.onInput, {
    super.key,
    this.borderRadius = 25.0,
    this.hintText = 'Ask me anything',
  });

  final ChatBoxCallback onInput;
  final double borderRadius;
  final String hintText;

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: !_isSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
        ),
        suffixIcon: _isSubmitted
            ? null
            : IconButton(icon: const Icon(Icons.send), onPressed: _submit),
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
    setState(() => _isSubmitted = true);
    widget.onInput(inputText);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
