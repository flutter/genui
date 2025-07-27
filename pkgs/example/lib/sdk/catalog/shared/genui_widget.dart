import 'package:flutter/material.dart';

import '../../model/agent.dart';
import '../../model/input.dart';

class GenUiWidget extends StatefulWidget {
  const GenUiWidget(this.input, this.agent);

  final GenUiAgent agent;
  final Input input;

  @override
  State<GenUiWidget> createState() => _GenUiWidgetState();
}

class _GenUiWidgetState extends State<GenUiWidget> {
  WidgetBuilder? _widgetBuilder;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final builder = await widget.agent.request(widget.input);
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
