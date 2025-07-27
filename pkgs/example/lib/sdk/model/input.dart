sealed class Input {}

class InitialInput extends Input {
  final String initialPrompt;
  InitialInput(this.initialPrompt);
}

class UserInput extends Input {}

typedef UserInputCallback = void Function(UserInput input);

class ChatBoxInput extends UserInput {
  final String text;
  ChatBoxInput(this.text);
}
