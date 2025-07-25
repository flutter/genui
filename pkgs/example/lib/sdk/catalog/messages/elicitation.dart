import 'package:flutter/material.dart';

import '../../model/genui_controller.dart';
import '../../model/simple_items.dart';
import '../elements/agent_icon.dart';
import '../elements/text_intro.dart';

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
        const SizedBox(height: 8.0),
        const Text('filter will be here'),
      ],
    );
  }
}

class ElicitationData extends WidgetData {
  final TextIntroData textIntroData;

  ElicitationData({required this.textIntroData});
}
