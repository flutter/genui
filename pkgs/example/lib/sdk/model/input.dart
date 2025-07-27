sealed class Input {}

class InvitationInput extends Input {
  final String invitationPrompt;
  InvitationInput(this.invitationPrompt);
}

class UserInput extends Input {}

typedef UserInputCallback = void Function(UserInput input);

class ChatBoxInput extends UserInput {
  final String text;
  ChatBoxInput(this.text);
}
