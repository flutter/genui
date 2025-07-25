import 'package:example/sdk/agent/input.dart';

abstract class WidgetData {}

/// A controller for GenUi that can be used to manage state or handle events.
class GenUiController {
  GenUiController(this.imageCatalog);

  final ImageCatalog imageCatalog;

  void dispose() {}
}
