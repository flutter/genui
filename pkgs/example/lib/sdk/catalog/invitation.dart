import 'package:example/sdk/catalog/carousel.dart';
import 'package:example/sdk/catalog/chat_box.dart';
import 'package:example/sdk/catalog/shared/text_styles.dart';
import 'package:example/sdk/catalog/text_intro.dart';
import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

class Invitation extends StatelessWidget {
  final InvitationData data;
  final GenUiController controller;

  const Invitation({super.key, required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextIntro(data: data.textIntroData),
        Text(data.exploreTitle, style: GenUiTextStyles.h2(context)),
        Carousel(data: CarouselData(items: data.exploreItems)),
        Padding(padding: const EdgeInsets.only(top: 16.0), child: ChatBox()),
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
