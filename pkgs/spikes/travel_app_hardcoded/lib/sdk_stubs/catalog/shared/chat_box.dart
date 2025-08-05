// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../model/input.dart';

class ChatBox extends StatefulWidget {
  ChatBox(this.onInput, {super.key});

  final UserInputCallback onInput;

  /// Fake input to simulate pre-filled text in the chat box.
  ///
  /// TODO(polina-c): Remove this in productized version.
  final String fakeInput =
      'I have 3 days in Zermatt with my wife and 11 year old daughter, '
      'and I am wondering how to make the most out of our time.';

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      // Reset the input on focus.
      if (widget.fakeInput.isNotEmpty &&
          !_isSubmitted &&
          _focusNode.hasFocus &&
          _controller.text.isEmpty) {
        setState(() => _controller.text = widget.fakeInput);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: !_isSubmitted,
      decoration: InputDecoration(
        hintText: 'Ask me anything',
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
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
    widget.onInput(ChatBoxInput(inputText));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
