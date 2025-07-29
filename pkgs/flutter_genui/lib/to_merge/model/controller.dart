import 'dart:async';

import 'package:flutter/widgets.dart';

import 'input.dart';
import 'simple_items.dart';
import 'image_catalog.dart';

typedef InputCallback = void Function(Input input);

class GenUiController {
  final ImageCatalog imageCatalog;
  final String agentIconAsset;

  final ScrollController scrollController;
  final GenUiState state = GenUiState();

  Widget icon({double? width, double? height}) {
    return Image.asset(width: width, height: height, agentIconAsset);
  }

  GenUiController(
    this.scrollController, {
    required this.imageCatalog,
    required this.agentIconAsset,
  });
}

/// Controller for the GenUi operations.
///
/// TODO (polina-c): protect the fields from being mutated by the user.
///
/// TODO (polina-c): handle race conditions when the input is changed
/// while the agent is processing it.
class GenUiState {
  Completer<Input> input = Completer<Input>();

  Completer<WidgetBuilder> builder = Completer<WidgetBuilder>();

  final List<({Input input, WidgetData data})> history = [];
}
