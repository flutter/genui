import 'package:example/sdk/agent/fake_output.dart';
import 'package:example/sdk/agent/input.dart';
import 'package:example/sdk/catalog/invitation.dart';
import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/widgets.dart';

class GenUiAgent {
  static final GenUiAgent instance = GenUiAgent._();

  GenUiAgent._();

  Future<WidgetBuilder> request(Input input, GenUiController controller) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    return switch (input) {
      InvitationInput _ => (_) => Invitation(
        data: fakeInvitationData,
        controller: controller,
      ),
      _ => throw UnimplementedError(
        'GenUiAgent does not support input of type ${input.runtimeType}',
      ),
    };
  }
}
