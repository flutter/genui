// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_chat/db/climbing_db.dart';
import 'package:simple_chat/widgets/climbing.dart';

void main() {
  testWidgets('ClimbingLocation renders correctly', (
    WidgetTester tester,
  ) async {
    const info = ClimbingLocationInfo(
      identifier: 'test_gym',
      image: '10x2500x1667.jpg',
      name: 'Test Gym',
      address: '123 Test St',
      climbingTypes: [ClimbingType.bouldering, ClimbingType.topRope],
      experienceRanges: [
        ExperienceRange.beginner,
        ExperienceRange.intermediate,
      ],
      properties: [
        LocationProperty.indoor,
        LocationProperty.paid,
        LocationProperty.permitRequired,
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ClimbingLocation(info: info)),
      ),
    );

    // Verify name and address
    expect(find.text('Test Gym'), findsOneWidget);
    expect(find.text('123 Test St'), findsOneWidget);

    // Verify chips
    expect(find.text('Bouldering'), findsOneWidget);
    expect(find.text('Top Rope'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);

    // Verify badges
    expect(find.text('Indoor'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Permit Required'), findsOneWidget);
  });
}
