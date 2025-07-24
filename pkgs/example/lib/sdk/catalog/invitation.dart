import 'package:example/sdk/catalog/carousel.dart';
import 'package:example/sdk/catalog/text_intro.dart';
import 'package:example/sdk/model/base_classes.dart';
import 'package:flutter/material.dart';

class Invitation extends StatelessWidget {
  final InvitationData data;
  final EventHandler handler;

  const Invitation({super.key, required this.data, required this.handler});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
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
