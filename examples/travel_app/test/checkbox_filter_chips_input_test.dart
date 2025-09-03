// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/catalog/checkbox_filter_chips_input.dart';

void main() {
  testWidgets('CheckboxFilterChipsInput golden test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: checkboxFilterChipsInput.widgetBuilder(
              data: {
                'chipLabel': 'Amenities',
                'options': ['Wifi', 'Pool', 'Gym'],
                'initialOptions': ['Wifi', 'Gym'],
                'iconName': 'hotel',
              },
              id: 'test',
              buildChild: (_) => const SizedBox(),
              dispatchEvent: (_) {},
              context: null,
              values: {},
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/checkbox_filter_chips_input.png'),
    );
  });
}
