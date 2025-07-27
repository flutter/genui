import 'package:flutter/material.dart';

import '../../model/agent.dart';
import '../../model/input.dart';
import '../../model/simple_items.dart';
import '../elements/text_intro.dart';
import '../shared/genui_widget.dart';
import '../shared/text_styles.dart';

class Elicitation extends StatefulWidget {
  final ElicitationData data;
  final GenUiAgent agent;

  const Elicitation(this.data, this.agent, {super.key});

  @override
  State<Elicitation> createState() => _ElicitationState();
}

class _ElicitationState extends State<Elicitation> {
  final ValueNotifier<UserInput?> _input = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.agent.icon(width: 40, height: 40),
        const SizedBox(height: 8.0),
        TextIntro(widget.data.textIntroData),
        const SizedBox(height: 16.0),
        Text('filter will be here', style: GenUiTextStyles.h2(context)),

        const SizedBox(height: 16.0),
        ValueListenableBuilder<UserInput?>(
          valueListenable: _input,
          builder: (context, input, child) {
            if (input == null) return const SizedBox.shrink();
            return GenUiWidget(input, widget.agent);
          },
        ),
      ],
    );
  }

  void onInput(UserInput input) {
    _input.value = input;
  }
}

class ElicitationData extends WidgetData {
  final TextIntroData textIntroData;

  ElicitationData({required this.textIntroData});
}
