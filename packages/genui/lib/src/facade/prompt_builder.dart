import '../../genui.dart';

class SurfaceOperations {
  const SurfaceOperations({
    this.create = true,
    this.update = false,
    this.delete = false,
  });

  final bool create;
  final bool update;
  final bool delete;
}

class PromptBuilder {
  PromptBuilder(this.catalog, this.allowedOperations);

  final Catalog catalog;
  final SurfaceOperations allowedOperations;
}
