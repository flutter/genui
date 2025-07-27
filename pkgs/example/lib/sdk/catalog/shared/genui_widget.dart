import 'package:flutter/material.dart';

import '../../model/agent.dart';
import '../../model/input.dart';

class GenUi extends StatefulWidget {
  const GenUi(this.initialPrompt, this.agent);

  final GenUiAgent agent;
  final String initialPrompt;

  @override
  State<GenUi> createState() => _GenUiState();
}

class _GenUiState extends State<GenUi> {
  WidgetBuilder? _widgetBuilder;
  bool isWaiting = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final builder = await widget.agent.request(
      InitialInput(widget.initialPrompt),
    );
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
