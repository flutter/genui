import 'package:example/sdk/catalog/elements/agent_icon.dart';

import 'package:example/sdk/catalog/elements/text_intro.dart';
import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

class Elicitation extends StatelessWidget {
  final ElicitationData data;
  final GenUiController controller;

  const Elicitation({super.key, required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentIcon(controller),
        SizedBox(height: 8.0),
        Text('filter will be here'),
      ],
    );
  }
}

class ElicitationData extends WidgetData {
  final TextIntroData textIntroData;

  ElicitationData({required this.textIntroData});
}
