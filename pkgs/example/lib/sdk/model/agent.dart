import 'package:flutter/widgets.dart';

import 'input.dart';

abstract class GenUiAgent {
  Future<WidgetBuilder> request(Input input);

  Widget icon({double? width, double? height});

  void dispose();
}
