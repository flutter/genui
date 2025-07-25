import 'package:example/sdk/catalog/shared/text_styles.dart';
import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

class TextIntro extends StatelessWidget {
  const TextIntro({super.key, required this.data});

  final TextIntroData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.h1, style: GenUiTextStyles.h1(context)),
        const SizedBox(height: 8.0),
        Text(data.h2, style: GenUiTextStyles.h2(context)),
        const SizedBox(height: 16.0),
        Text(data.intro, style: GenUiTextStyles.normal(context)),
      ],
    );
  }
}

class TextIntroData extends WidgetData {
  final String h1;
  final String h2;
  final String intro;

  TextIntroData({required this.h1, required this.h2, required this.intro});
}
