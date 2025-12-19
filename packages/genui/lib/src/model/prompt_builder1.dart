class ToolSet {}

sealed class GenUiConfiguration {
  static GenUiConfiguration custom(String prompt, ToolSet toolSet) =>
      _CustomGenUiConfiguration(prompt, toolSet);

  static GenUiConfiguration basic(
    String prompt, {
    bool allowSurfaceCreation = true,
    bool allowSurfaceUpdate = false,
    bool allowSurfaceDeletion = false,
  }) => _BasicGenUiConfiguration(
    prompt,
    allowSurfaceCreation: allowSurfaceCreation,
    allowSurfaceUpdate: allowSurfaceUpdate,
    allowSurfaceDeletion: allowSurfaceDeletion,
  );

  String prompt();

  ToolSet toolSet();
}

class _CustomGenUiConfiguration implements GenUiConfiguration {
  final String _prompt;
  final ToolSet _toolSet;

  _CustomGenUiConfiguration(this._prompt, this._toolSet);

  @override
  String prompt() => _prompt;

  @override
  ToolSet toolSet() => _toolSet;
}

class _BasicGenUiConfiguration implements GenUiConfiguration {
  final String _prompt;
  final bool allowSurfaceCreation;
  final bool allowSurfaceUpdate;
  final bool allowSurfaceDeletion;

  _BasicGenUiConfiguration(
    this._prompt, {
    required this.allowSurfaceCreation,
    required this.allowSurfaceUpdate,
    required this.allowSurfaceDeletion,
  });

  @override
  String prompt() => throw UnimplementedError();

  @override
  ToolSet toolSet() => throw UnimplementedError();
}
