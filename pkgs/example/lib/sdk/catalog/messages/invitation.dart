import 'package:flutter/material.dart';

import '../../model/genui_controller.dart';
import '../../model/input.dart';
import '../../model/simple_items.dart';
import '../elements/agent_icon.dart';
import '../elements/carousel.dart';
import '../elements/chat_box.dart';
import '../elements/text_intro.dart';
import '../shared/text_styles.dart';

class Invitation extends StatefulWidget {
  final InvitationData data;
  final GenUiController controller;

  const Invitation(this.data, this.controller, {super.key});

  @override
  State<Invitation> createState() => _InvitationState();
}

class _InvitationState extends State<Invitation> {
  final ValueNotifier<UserInput?> _input = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    // TODO(polina-c): move sizes to shared constants.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentIcon(widget.controller),
        const SizedBox(height: 8.0),
        TextIntro(widget.data.textIntroData),
        const SizedBox(height: 16.0),
        Text(widget.data.exploreTitle, style: GenUiTextStyles.h2(context)),
        Carousel(CarouselData(items: widget.data.exploreItems), onInput),
        const SizedBox(height: 16.0),
        ChatBox(
          onInput,
          fakeInput:
              'I have 3 days in Zermatt with my wife and 11 year old daughter, '
              'and I am wondering how to make the most out of our time.',
        ),
        const SizedBox(height: 16.0),
        ValueListenableBuilder<UserInput?>(
          valueListenable: _input,
          builder: (context, input, child) {
            if (input == null) return const SizedBox.shrink();
            widget.controller.handleInput(input);
            _input.value = null; // Reset after handling input
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  void onInput(UserInput input) {
    _input.value = input;
  }
}

class InvitationData extends WidgetData {
  final TextIntroData textIntroData;
  final String exploreTitle;
  final List<CarouselItemData> exploreItems;
  final String chatHintText;

  InvitationData({
    required this.textIntroData,
    required this.exploreTitle,
    required this.chatHintText,
    required this.exploreItems,
  });
}
