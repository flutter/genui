import 'package:example/sdk/agent/fake_output.dart';
import 'package:example/sdk/agent/input.dart';
import 'package:example/sdk/catalog/invitation.dart';
import 'package:example/sdk/model/base_classes.dart';
import 'package:flutter/widgets.dart';

class GenUiAgent {
  Future<Widget> request(Input input, EventHandler handler) async {
    switch (input.runtimeType) {
      case InvitationInput _:
        return Invitation(data: fakeInvitationData, handler: handler);
      default:
        throw Exception('Unsupported input type: ${input.runtimeType}');
    }
  }
}
