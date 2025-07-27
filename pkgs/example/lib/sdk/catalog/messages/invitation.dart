import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/agent.dart';
import '../../model/input.dart';
import '../../model/simple_items.dart';
import '../elements/carousel.dart';
import '../elements/chat_box.dart';
import '../elements/text_intro.dart';
import '../shared/genui_widget.dart';
import '../shared/text_styles.dart';

class Invitation extends StatefulWidget {
  final InvitationData data;
  final GenUiAgent agent;

  const Invitation(this.data, this.agent, {super.key});

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
        widget.agent.icon(width: 40, height: 40),
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
        const SizedBox(height: 28.0),
        GenUiWidget.wait(_input, widget.agent),
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
