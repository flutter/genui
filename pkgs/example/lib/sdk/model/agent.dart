import 'dart:async';

import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'input.dart';
import 'simple_items.dart';

abstract class GenUiAgent {
  final GenUiController controller;

  GenUiAgent(this.controller);

  void submitInput(Input input);

  /// The current round of interaction with the agent.
  ///
  /// Should be mutated only by agent methods.
  /// TODO: make immutable.
  GenUiRound round = GenUiRound();

  Widget icon({double? width, double? height}) {
    return Image.asset(width: 40, height: 40, controller.agentIconAsset);
  }
}

class GenUiRound {
  final input = Completer<Input>();
  final output = Completer<WidgetData>();
  final Completer<WidgetBuilder> builder = Completer<WidgetBuilder>();
}
