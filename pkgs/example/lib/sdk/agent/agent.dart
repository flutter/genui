import 'package:flutter/widgets.dart';

import '../catalog/messages/invitation.dart';
import '../model/agent.dart';
import '../model/assets.dart';
import '../model/input.dart';
import '../model/simple_items.dart';
import 'fake_output.dart';

class SimpleGenUiAgent implements GenUiAgent {
  SimpleGenUiAgent(this.assets);

  final GenUiAssets assets;

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
      case UserInput():
        throw UnimplementedError(
          'The agent does not support input of type ${input.runtimeType}',
        );
    }

    _history.add((input: input, output: output));

    return result;
  }

  @override
  Widget icon({double? width, double? height}) {
    return Image.asset(width: 40, height: 40, assets.agentIconAsset);
  }

  @override
  void dispose() {}
}
