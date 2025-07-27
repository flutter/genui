import 'package:flutter/widgets.dart';

import '../catalog/messages/invitation.dart';
import '../model/genui_controller.dart';
import '../model/input.dart';
import 'fake_output.dart';

class GenUiAgentImpl implements GenUiAgent {
  final GenUiController controller;

  GenUiAgentImpl(this.controller);

  @override
  Future<WidgetBuilder> request(Input input) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    return switch (input) {
      InvitationInput _ => (_) => Invitation(fakeInvitationData, controller),
      _ => throw UnimplementedError(
        'GenUiAgent does not support input of type ${input.runtimeType}',
      ),
    };
  }
}
