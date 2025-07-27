import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'input.dart';

abstract class GenUiAgent {
  final GenUiController controller;

  GenUiAgent(this.controller);

  Future<WidgetBuilder> request(Input input);

  Widget icon({double? width, double? height}) {
    return Image.asset(width: 40, height: 40, controller.agentIconAsset);
  }

  void dispose() {}
}
