// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A callback that is called when the user submits a chat message.
typedef ChatBoxCallback = void Function(String input);

/// A builder for a chat box widget.
typedef ChatBoxBuilder =
    Widget Function(ChatBoxController controller, BuildContext context);

/// The default chat box builder.
Widget defaultChatBoxBuilder(
  ChatBoxController controller,
  BuildContext context,
) => ChatBox(controller);

/// A controller for a chat box.
///
/// This controller is used to manage the state of the chat box, such as
/// whether it is waiting for a response from the AI.
class ChatBoxController {
  /// Creates a new [ChatBoxController].
  ChatBoxController(this.onInput);

  /// Is invoked when the user submits input.
  ///
  /// User can submit input without waiting for a response.
  ChatBoxCallback onInput;

  final ValueNotifier<bool> _isWaiting = ValueNotifier<bool>(false);

  /// A [ValueListenable] that indicates whether the chat box is waiting for a
  /// response from the AI.
  late final ValueListenable<bool> isWaiting = _isWaiting;

  /// Sets the chat box to the waiting state.
  void setRequested() {
    _isWaiting.value = true;
  }

  /// Sets the chat box to the not-waiting state.
  void setResponded() {
    _isWaiting.value = false;
  }

  /// Disposes of the resources used by the controller.
  void dispose() {
    _isWaiting.dispose();
  }
}

/// A widget that provides a text input field for a chat interface.
class ChatBox extends StatefulWidget {
  /// Creates a new [ChatBox].
  ChatBox(
    this.controller, {
    super.key,
    this.borderRadius = 25.0,
    this.hintText = 'Ask me anything',
  });

  /// The controller for the chat box.
  final ChatBoxController controller;

  /// The border radius of the text field.
  final double borderRadius;

  /// The hint text to display in the text field.
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
