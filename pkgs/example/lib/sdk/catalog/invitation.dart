import 'package:example/sdk/catalog/carousel.dart';
import 'package:example/sdk/catalog/text_intro.dart';
import 'package:flutter/material.dart';

class Invitation extends StatelessWidget {
  final InvitationData data;
  const Invitation({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class InvitationData {
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
