import 'package:example/sdk/catalog/elements/agent_icon.dart';
import 'package:example/sdk/catalog/elements/carousel.dart';
import 'package:example/sdk/catalog/elements/chat_box.dart';
import 'package:example/sdk/catalog/shared/text_styles.dart';
import 'package:example/sdk/catalog/elements/text_intro.dart';
import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

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
        SizedBox(height: 8.0),
        TextIntro(data.textIntroData),
        SizedBox(height: 16.0),
        Text(data.exploreTitle, style: GenUiTextStyles.h2(context)),
        Carousel(CarouselData(items: data.exploreItems)),
        SizedBox(height: 16.0),
        ChatBox(),
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
