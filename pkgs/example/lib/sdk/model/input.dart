sealed class Input {}

class InvitationInput extends Input {
  final String invitationPrompt;
  InvitationInput(this.invitationPrompt);
}

class UserInput extends Input {}

class ChatBoxInput extends UserInput {
  final String text;
  ChatBoxInput(this.text);
}
