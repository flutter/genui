import 'package:flutter/widgets.dart';

import '../catalog/messages/elicitation.dart';
import '../catalog/messages/invitation.dart';
import '../model/agent.dart';
import '../model/input.dart';
import '../model/simple_items.dart';
import 'fake_output.dart';

class SimpleGenUiAgent extends GenUiAgent {
  SimpleGenUiAgent(super.controller);

  final List<({Input input, WidgetData output})> _history = [];

  @override
  Future<WidgetBuilder> request(Input input) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    late final WidgetData output;
    late final WidgetBuilder result;

    switch (input) {
      case InitialInput():
        output = fakeInvitationData;
        result = (_) => Invitation(fakeInvitationData, this);
      case ChatBoxInput():
        output = fakeElicitationData;
        result = (_) => Elicitation(fakeElicitationData, this);
      default:
        throw UnimplementedError(
          'The agent does not support input of type ${input.runtimeType}',
        );
    }

    _history.add((input: input, output: output));

    return result;
  }
}
