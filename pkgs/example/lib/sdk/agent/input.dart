class ImageCatalog {}

sealed class Input {
  const Input._();
}

class InvitationInput extends Input {
  final String invitationPrompt;
  InvitationInput(this.invitationPrompt) : super._();
}

class UserInput extends Input {
  UserInput() : super._();
}
