import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/agent.dart';
import '../../model/input.dart';

class GenUiWidget extends StatefulWidget {
  factory GenUiWidget(Input input, GenUiAgent agent) =>
      GenUiWidget.wait(Completer<Input>()..complete(input), agent);

  const GenUiWidget.wait(this.input, this.agent, {super.key});

  final Completer<Input> input;
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
    final input = await widget.input.future;
    setState(() => _input = input);
    final builder = await widget.agent.request(input);
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
    if (_input == null) return const SizedBox.shrink();
    final builder = _builder;
    if (builder == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return builder(context);
  }
}
