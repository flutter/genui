// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

typedef ChatBoxCallback = void Function(String input);

typedef ChatBoxBuilder =
    Widget Function(ChatController controller, BuildContext context);

Widget defaultChatBoxBuilder(ChatController controller, BuildContext context) =>
    ChatBox(controller);

class ChatController {
  ChatController(this.onInput);

  /// Is invoked when the user submits input.
  ///
  /// User can submit input multiple times, so this callback
  /// should be able to handle multiple invocations.
  ChatBoxCallback onInput;

  final List<String> history = [];

  /// At least one request to AI is sent.
  final _requested = Completer<void>();

  /// At least one response from AI is received.
  final _responded = Completer<void>();

  Future<void> get requested => _requested.future;

  Future<void> get responded => _responded.future;

  bool get isRequested => _requested.isCompleted;
  bool get isResponded => _responded.isCompleted;

  void setRequested() {
    if (!_requested.isCompleted) {
      _requested.complete();
    }
  }

  void setResponded() {
    if (!_responded.isCompleted) {
      _responded.complete();
    }
  }

  void submitInput(String input) {
    onInput(input);
    history.add(input);
  }

  void dispose() {
    _requested.complete();
    _responded.complete();
  }
}

class ChatBox extends StatefulWidget {
  ChatBox(
    this.controller, {
    super.key,
    this.borderRadius = 25.0,
    this.hintText = 'Ask me anything',
  });

  final ChatController controller;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _waitForActivity();
  }

  @override
  void didUpdateWidget(covariant ChatBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _waitForActivity();
    }
  }

  Future<void> _waitForActivity() async {
    setState(() {});
    await widget.controller._requested.future;
    setState(() {});
    await widget.controller._responded.future;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isRequested = widget.controller.isRequested;
    final isResponded = widget.controller.isResponded;
    final isProgressing = isRequested && !isResponded;

    final history = widget.controller.history.map(
      (e) => Padding(
        padding: const EdgeInsets.all(0),
        child: Card(
          elevation: 0,
          child: Padding(padding: const EdgeInsets.all(8.0), child: Text(e)),
        ),
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...history,
        if (isProgressing) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 10),
        ],
        if (!isResponded)
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(widget.borderRadius),
                ),
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
          ),
      ],
    );
  }

  void _submit() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    widget.controller.submitInput(input);
    _controller.text = '';
    _focusNode.requestFocus();
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
