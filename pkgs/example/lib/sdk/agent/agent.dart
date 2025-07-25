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
    await Future.delayed(const Duration(milliseconds: 1500));
    switch (input.runtimeType) {
      case InvitationInput _:
        return (_) =>
            Invitation(data: fakeInvitationData, controller: controller);
      default:
        throw Exception('Unsupported input type: ${input.runtimeType}');
    }
  }
}
