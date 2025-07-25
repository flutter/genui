import 'package:flutter/widgets.dart';

import '../catalog/messages/invitation.dart';
import '../model/simple_items.dart';
import 'fake_output.dart';
import 'input.dart';

class GenUiAgent {
  static final GenUiAgent instance = GenUiAgent._();

  GenUiAgent._();

  Future<WidgetBuilder> request(Input input, GenUiController controller) async {
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
