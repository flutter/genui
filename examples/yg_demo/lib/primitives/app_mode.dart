/// Defines the mode of the application.
enum AppMode {
  /// Agent responds with text only.
  textOnly('Text only'),

  /// Agent responds with text and the basic catalog items.
  basicCatalog('Basic catalog'),

  /// Agent responds with text and custom catalog items.
  customCatalog('Custom catalog');

  const AppMode(this.displayName);

  /// The user-friendly name of the app mode.
  final String displayName;
}
