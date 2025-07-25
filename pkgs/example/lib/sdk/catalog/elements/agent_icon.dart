import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

class AgentIcon extends StatelessWidget {
  final GenUiController controller;
  const AgentIcon(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(width: 40, height: 40, controller.agentIcon);
  }
}
