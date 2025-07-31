import 'package:flutter/material.dart';

import '../../model/controller.dart';
import '../../model/input.dart';
import '../../model/simple_items.dart';
import '../elements/text_intro.dart';

class Result extends StatefulWidget {
  final ResultData data;
  final GenUiController controller;

  const Result(this.data, this.controller, {super.key});

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  final ValueNotifier<UserInput?> _input = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.controller.icon(width: 40, height: 40),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Image.asset(widget.data.imageAssetUrl, width: 40, height: 40),
            const SizedBox(width: 8.0),
            Expanded(child: TextIntro(widget.data.textIntroData)),
          ],
        ),
      ],
    );
  }

  void onInput(UserInput input) {
    _input.value = input;
  }
}

class ResultData extends WidgetData {
  final TextIntroData textIntroData;
  final String imageAssetUrl;
  final String linkUrl;

  ResultData({
    required this.textIntroData,
    required this.imageAssetUrl,
    required this.linkUrl,
  });
}
