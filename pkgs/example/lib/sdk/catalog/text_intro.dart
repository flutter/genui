import 'package:flutter/material.dart';

class TextIntro extends StatelessWidget {
  const TextIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TextIntroData {
  final String h1;
  final String h2;
  final String intro;

  TextIntroData({required this.h1, required this.h2, required this.intro});
}
