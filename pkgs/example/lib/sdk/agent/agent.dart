import 'package:example/sdk/agent/input.dart';
import 'package:flutter/widgets.dart';

class GenUiAgent {
  Widget request(Input input) {
    return Text('Request processed: $input');
  }
}
