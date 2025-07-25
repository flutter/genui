import 'package:example/sdk/catalog/elements/carousel.dart';
import 'package:example/sdk/catalog/elements/chat_box.dart';
import 'package:example/sdk/catalog/shared/text_styles.dart';
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
        Image.asset(controller.agentIcon),
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

class ElicitationData extends WidgetData {
  final TextIntroData textIntroData;
  final String exploreTitle;
  final List<CarouselItemData> exploreItems;
  final String chatHintText;

  ElicitationData({
    required this.textIntroData,
    required this.exploreTitle,
    required this.chatHintText,
    required this.exploreItems,
  });
}
