import 'package:flutter/material.dart';

import '../model/genui_controller.dart';
import '../model/input.dart';
import 'agent.dart';

class GenUi extends StatefulWidget {
  const GenUi.invitation({
    super.key,
    required this.controller,
    required this.initialPrompt,
  });

  final GenUiController controller;
  final String initialPrompt;

  @override
  State<GenUi> createState() => _GenUiState();
}

class _GenUiState extends State<GenUi> {
  late final GenUiAgent _agent;
  WidgetBuilder? _widgetBuilder;
  bool isWaiting = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _agent = GenUiAgentImpl(widget.controller);
    final builder = await _agent.request(InvitationInput(widget.initialPrompt));
    setState(() {
      _widgetBuilder = builder;
      isWaiting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isWaiting) {
      return const Center(child: CircularProgressIndicator());
    }
    final builder = _widgetBuilder!;
    _widgetBuilder = null;
    return builder(context);
  }
}
