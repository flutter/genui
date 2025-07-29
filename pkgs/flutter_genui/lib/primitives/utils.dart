import 'package:flutter/widgets.dart';

Future<void> scrollToBottom(ScrollController controller) async {
  await controller.animateTo(
    controller.position.maxScrollExtent,
    duration: const Duration(milliseconds: 600),
    curve: Curves.fastOutSlowIn,
  );
}
