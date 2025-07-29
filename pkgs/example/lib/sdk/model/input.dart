import 'package:flutter/material.dart';

sealed class Input {
  Widget build(BuildContext context) {
    return Text('Visualization for $runtimeType is not implemented.');
  }
}

class InitialInput extends Input {
  final String initialPrompt;
  InitialInput(this.initialPrompt);
}

class UserInput extends Input {}

typedef UserInputCallback = void Function(UserInput input);

class ChatBoxInput extends UserInput {
  final String text;
  ChatBoxInput(this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(padding: const EdgeInsets.all(16.0), child: Text(text)),
    );
  }
}
