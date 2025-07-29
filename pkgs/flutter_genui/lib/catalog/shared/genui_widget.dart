import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/controller.dart';
import '../../model/input.dart';
import '../elements/chat_box.dart';

class GenUiWidget extends StatefulWidget {
  GenUiWidget(this.controller);

  final GenUiController controller;

  @override
  State<GenUiWidget> createState() => _GenUiWidgetState();
}

class _GenUiWidgetState extends State<GenUiWidget> {
  Input? _input;
  WidgetBuilder? _builder;

  @override
  void initState() {
    print('Initializing GenUiWidget');
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChatInput(context),
        const SizedBox(height: 16.0),
        if (builder == null)
          const Center(child: CircularProgressIndicator())
        else
          builder(context),
      ],
    );
  }

  void _onInput(UserInput input) {
    widget.controller.state.input.complete(input);
    widget.controller.state.builder = Completer<WidgetBuilder>();
    _initialize();
  }

  Widget _buildChatBox() {
    return ChatBox(_onInput);
  }

  Widget _buildChatInput(BuildContext context) {
    return _input?.build(context) ?? const SizedBox.shrink();
  }
}
