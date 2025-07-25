import 'package:flutter/material.dart';

import '../../model/genui_controller.dart';
import '../../model/simple_items.dart';
import '../elements/agent_icon.dart';
import '../elements/carousel.dart';
import '../elements/chat_box.dart';
import '../elements/text_intro.dart';
import '../shared/text_styles.dart';

class Invitation extends StatelessWidget {
  final InvitationData data;
  final GenUiController controller;

  const Invitation(this.data, this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentIcon(controller),
        const SizedBox(height: 8.0),
        TextIntro(data.textIntroData),
        const SizedBox(height: 16.0),
        Text(data.exploreTitle, style: GenUiTextStyles.h2(context)),
        Carousel(CarouselData(items: data.exploreItems)),
        const SizedBox(height: 16.0),
        ChatBox(
          controller,
          fakeInput:
              'I have 3 days in Zermatt with my wife and 11 year old daughter, '
              'and I am wondering how to make the most out of our time.',
        ),
      ],
    );
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
