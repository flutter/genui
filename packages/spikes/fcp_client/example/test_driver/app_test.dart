// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Cosmic Dashboard App', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('compliment text changes on button tap', () async {
      final complimentTextFinder = find.byValueKey('compliment_text');
      final initialCompliment = await driver.getText(complimentTextFinder);

      final buttonFinder = find.byValueKey('compliment_button');
      await driver.tap(buttonFinder);

      await driver.waitFor(find.text('You are as bright as a supernova!'));

      final newCompliment = await driver.getText(complimentTextFinder);
      expect(newCompliment, isNot(initialCompliment));
    });

    test(
      'toggling details checkbox adds and removes the details widget',
      () async {
        final detailsTextFinder = find.byValueKey('details_text');
        final toggleFinder = find.byValueKey('details_toggle');

        // Details should be absent initially.
        await driver.waitForAbsent(detailsTextFinder);

        // Tap checkbox to show details.
        await driver.tap(toggleFinder);
        await driver.waitFor(detailsTextFinder);

        // Tap checkbox again to hide details.
        await driver.tap(toggleFinder);
        await driver.waitForAbsent(detailsTextFinder);
      },
    );
  });
}
