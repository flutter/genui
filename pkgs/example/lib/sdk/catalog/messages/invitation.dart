import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/controller.dart';
import '../../model/input.dart';
import '../../model/simple_items.dart';
import '../elements/carousel.dart';
import '../elements/text_intro.dart';
import '../shared/genui_widget.dart';
import '../shared/text_styles.dart';

class Invitation extends StatefulWidget {
  final InvitationData data;
  final GenUiController genUi;

  const Invitation(this.data, this.genUi, {super.key});

  @override
  State<Invitation> createState() => _InvitationState();
}

class _InvitationState extends State<Invitation> {
  final _input = Completer<Input>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.genUi.icon(width: 40, height: 40),
        const SizedBox(height: 8.0),
        TextIntro(widget.data.textIntroData),
        const SizedBox(height: 16.0),
        Text(widget.data.exploreTitle, style: GenUiTextStyles.h2(context)),
        Carousel(CarouselData(items: widget.data.exploreItems), onInput),
        const SizedBox(height: 16.0),

        GenUiWidget(widget.genUi),
      ],
    );
  }

  void onInput(UserInput input) {
    _input.complete(input);
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
