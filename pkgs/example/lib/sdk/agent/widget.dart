import 'package:flutter/material.dart';

import '../model/simple_items.dart';
import 'agent.dart';
import 'input.dart';

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
  WidgetBuilder? _widgetBuilder;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final builder = await GenUiAgent.instance.request(
      InvitationInput(widget.initialPrompt),
      widget.controller,
    );
    setState(() => _widgetBuilder = builder);
  }

  @override
  Widget build(BuildContext context) {
    final builder = _widgetBuilder;
    if (builder == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return builder(context);
  }
}
