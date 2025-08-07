// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ChatBoxCallback = void Function(String input);

typedef ChatBoxBuilder =
    Widget Function(ChatBoxController controller, BuildContext context);

Widget defaultChatBoxBuilder(
  ChatBoxController controller,
  BuildContext context,
) => ChatBox(controller);

class ChatBoxController {
  ChatBoxController(this.onInput);

  /// Is invoked when the user submits input.
  ///
  /// User can submit input without waiting for a response.
  ChatBoxCallback onInput;

  final ValueNotifier<bool> _isWaiting = ValueNotifier<bool>(false);
  late final ValueListenable<bool> isWaiting = _isWaiting;

  void setRequested() {
    _isWaiting.value = true;
  }

  void setResponded() {
    _isWaiting.value = false;
  }

  void dispose() {
    _isWaiting.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: widget.controller.isWaiting,
          builder: (context, isWaiting, child) {
            return Visibility(
              visible: isWaiting,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 18.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          },
        ),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(widget.borderRadius),
                    ),
                  ),
                ),
                maxLines: null, // Allows for multi-line input
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (String value) => _submit(),
              ),
            ),
            // The icon is outside of text field,
            // because it also should respond to UI selections.
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _submit,
              iconSize: 28,
            ),
          ],
        ),
      ],
    );
  }

  void _submit() {
    var input = _controller.text.trim();
    if (input.isEmpty) return;
    widget.controller.onInput(input);
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
