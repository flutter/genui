import 'dart:async';

import 'package:flutter/widgets.dart';

import '../catalog/messages/elicitation.dart';
import '../catalog/messages/invitation.dart';
import '../model/agent.dart';
import '../model/input.dart';
import '../model/simple_items.dart';
import 'fake_output.dart';

class SimpleGenUiAgent extends GenUiAgent {
  SimpleGenUiAgent(super.controller);

  final List<GenUiRound> _history = [];

  Future<void> _request(Input input) async {
    round.input.complete(input);

    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    late final WidgetData output;
    late final WidgetBuilder builder;

    switch (input) {
      case InitialInput():
        output = fakeInvitationData;
        builder = (_) => Invitation(fakeInvitationData, this);
      case ChatBoxInput():
        output = fakeElicitationData;
        builder = (_) => Elicitation(fakeElicitationData, this);
      default:
        throw UnimplementedError(
          'The agent does not support input of type ${input.runtimeType}',
        );
    }

    round.output.complete(output);
    round.builder.complete(builder);
    _history.add(round);
  }
}
