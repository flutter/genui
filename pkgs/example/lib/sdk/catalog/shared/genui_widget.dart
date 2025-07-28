import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/controller.dart';
import '../../model/input.dart';
import '../elements/chat_box.dart';

class GenUiWidget extends StatefulWidget {
  GenUiWidget(this.controller, {Input? input}) {
    if (input != null) {
      controller.state.input.complete(input);
    }
  }

  final GenUiController controller;

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
    final state = widget.controller.state;

    final input = await state.input.future;
    setState(() => _input = input);
    final builder = await state.builder.future;
    setState(() => _builder = builder);
  }

  @override
  Widget build(BuildContext context) {
    if (_input == null) return _buildChatBox();

    final builder = _builder;

    if (builder == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        builder(context),
        const SizedBox(height: 16.0),
        _buildChatBox(),
      ],
    );
  }

  void _onInput(UserInput input) {
    widget.controller.state.input.complete(input);
    widget.controller.state.builder = Completer<WidgetBuilder>();
    _initialize();
  }

  Widget _buildChatBox() => ChatBox(_onInput);
}
