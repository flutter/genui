import 'package:flutter/material.dart';

import '../../model/_simple_items.dart';
import '../shared/text_styles.dart';

class TextIntro extends StatelessWidget {
  const TextIntro(this.data, {super.key});

  final TextIntroData data;

  @override
  Widget build(BuildContext context) {
    final h1 = data.h1;
    final h2 = data.h2;
    final intro = data.intro;

    final items = [
      ..._styledText(h1, GenUiTextStyles.h1(context)),
      ..._styledText(h2, GenUiTextStyles.h2(context)),
      ..._styledText(intro, GenUiTextStyles.normal(context)),
    ]..removeLast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  static List<Widget> _styledText(String? text, TextStyle style) {
    if (text == null) return [];
    return [Text(text, style: style), const SizedBox(height: 16.0)];
  }
}

class TextIntroData extends WidgetData {
  final String? h1;
  final String? h2;
  final String? intro;

  TextIntroData({this.h1, this.h2, this.intro});
}
