import 'package:flutter/widgets.dart';

import 'input.dart';
import 'simple_items.dart';

/// A controller for GenUi that can be used to manage state or handle events.
class GenUiController {
  GenUiController({required this.imageCatalog, required this.agentIconAsset});

  final ImageCatalog imageCatalog;
  final String agentIconAsset;

  final newUserInputNotifier = ValueNotifier<UserInput?>(null);

  void handleInput(UserInput input) {}

  void dispose() {
    newUserInputNotifier.dispose();
  }
}
