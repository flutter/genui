import 'package:flutter/material.dart';
import '../../model/input.dart';

class ChatBox extends StatefulWidget {
  ChatBox(this.onInput, {super.key, this.fakeInput = ''});

  final UserInputCallback onInput;

  /// Fake input to simulate pre-filled text in the chat box.
  ///
  /// TODO(polina-c): Remove this in productized version.
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
        setState(() => _controller.text = widget.fakeInput);
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
    print('!!!! Input submitted: ${_controller.text}');
    final inputText = _controller.text.trim();
    widget.onInput(ChatBoxInput(inputText));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
