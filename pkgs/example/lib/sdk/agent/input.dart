class ImageCatalog {}

sealed class Input {
  final ImageCatalog imageCatalog;

  const Input._(this.imageCatalog);
}

class InvitationInput extends Input {
  InvitationInput(super.imageCatalog) : super._();
}
