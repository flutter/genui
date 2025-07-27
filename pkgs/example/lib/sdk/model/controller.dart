import 'package:flutter/widgets.dart';

import 'simple_items.dart';

class GenUiController {
  final ImageCatalog imageCatalog;
  final String agentIconAsset;
  final ScrollController scrollController;

  GenUiController(
    this.scrollController, {
    required this.imageCatalog,
    required this.agentIconAsset,
  });
}
