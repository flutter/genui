import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/agent.dart';
import '../../model/input.dart';
import '../elements/chat_box.dart';

class GenUiWidget extends StatefulWidget {
  GenUiWidget(this.agent, {Input? input} ) {
    if (input != null) {
      agent.round.input.complete(input);
    }
  }

  final GenUiAgent agent;

  @override
  State<GenUiWidget> createState() => _GenUiWidgetState();
}

class _GenUiWidgetState extends State<GenUiWidget> {
  Input? _input;
  WidgetBuilder? _builder;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final input = await widget.agent.round.input.future;
    setState(() => _input = input);
    await widget.agent.request(input);
    setState(() => _builder = builder);

    // Scroll to the bottom after the widget is built
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final scroll = widget.agent.controller.scrollController;
    await scroll.animateTo(
      scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_input == null) {
      return ChatBox(
          onInput,
          // fakeInput:
          //     'I have 3 days in Zermatt with my wife and 11 year old daughter, '
          //     'and I am wondering how to make the most out of our time.',
        );
        const SizedBox(height: 28.0),
    }
    final builder = _builder;
    if (builder == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return builder(context);
  }
}
