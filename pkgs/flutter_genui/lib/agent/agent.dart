import 'dart:async';

import 'package:flutter/widgets.dart';

import '../_catalog/messages/elicitation.dart';
import '../_catalog/messages/invitation.dart';
import '../_catalog/shared/genui_widget.dart';
import '../_primitives/utils.dart';
import '../model/_simple_items.dart';
import '../model/controller.dart';
import '../model/input.dart';
import '_fake_output.dart';

class GenUiWidget extends StatelessWidget {
  const GenUiWidget(this.controller, {super.key});
  final GenUiController controller;

  @override
  Widget build(BuildContext context) {
    return GenUiWidgetInternal(controller);
  }
}

class GenUiAgent {
  GenUiAgent(this.controller);

  GenUiController controller;

  void run() => _startCycle();

  Future<void> _startCycle() async {
    while (true) {
      await _handleNextInput();
    }
  }

  void dispose() {
    // TODO: stop cycle
  }

  Future<void> _handleNextInput() async {
    final input = await controller.state.input.future;

    // Simulate network delay.
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    late final WidgetData data;
    late final WidgetBuilder builder;

    switch (input) {
      case InitialInput():
        data = fakeInvitationData;
        builder = (_) => Invitation(fakeInvitationData, controller);
      case ChatBoxInput():
        data = fakeElicitationData;
        builder = (_) => Elicitation(fakeElicitationData, controller);
      default:
        throw UnimplementedError(
          'The agent does not support input of type ${input.runtimeType}',
        );
    }

    final newInput = await controller.state.input.future;
    if (newInput != input) {
      // If the input has changed, we throw away the results.
      return;
    }

    // Provide the builder for the widget that wait for it.
    controller.state.builder.complete(builder);

    // Move the input and data to the history.
    controller.state.history.add((input: input, data: data));

    // Reset the input completer for the next input.
    controller.state.input = Completer<Input>();
    controller.state.builder = Completer<WidgetBuilder>();

    // Scroll to the bottom after the widget is built
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await scrollToBottom(controller.scrollController);
  }
}
