import 'package:flutter/material.dart';

import '../../model/genui_controller.dart';
import '../../model/simple_items.dart';

class ChatBox extends StatefulWidget {
  ChatBox(this.controller, {super.key, this.fakeInput = ''});

  final GenUiController controller;
  final String fakeInput;

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (widget.fakeInput.isNotEmpty) {
        _controller.text = widget.fakeInput;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Ask me anything',
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
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
    // widget.controller.handleInput(GenUiAgent.instance.createInput(inputText));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
