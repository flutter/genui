// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:travel_app/main.dart' as app;
import 'package:travel_app/src/fake_ai_client.dart';

void main() {
  configureGenUiLogging(level: Level.ALL);
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Initial UI test', () {
    testWidgets('send a request and verify the UI', (tester) async {
      final mockClient = FakeAiClient();
      runApp(app.TravelApp(aiClient: mockClient));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Plan a trip to Bali');
      await tester.tap(find.byIcon(Icons.send));

      mockClient.addA2uiMessage(A2uiMessage.fromJson(_baliCreateSurface));
      mockClient.addA2uiMessage(A2uiMessage.fromJson(_baliResponse));

      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Great! I can help you plan a fantastic trip to Bali. To '
          'get started, what kind of experience are you looking for?',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.text('Cultural Immersion', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Plan My Trip', findRichText: true), findsOneWidget);
    });
  });
}

const Map<String, Object> _baliCreateSurface = {
  'version': 'v0.9',
  'createSurface': {
    'surfaceId': 'bali_trip_planning_intro',
    'catalogId': 'https://a2ui.org/specification/v0_9/standard_catalog.json',
    'attachDataModel': true,
  },
};

const Map<String, Object> _baliResponse = {
  'version': 'v0.9',
  'updateComponents': {
    'surfaceId': 'bali_trip_planning_intro',
    'components': [
      {
        'id': 'root',
        'component': 'Column',
        'children': ['welcome_text', 'bali_carousel', 'trip_filters'],
        'spacing': 16,
        'crossAxisAlignment': 'start',
        'mainAxisAlignment': 'start',
      },
      {
        'id': 'welcome_text',
        'component': 'Text',
        'text':
            'Great! I can help you plan a fantastic trip to Bali. To '
            'get started, what kind of experience are you looking for?',
      },
      {
        'id': 'bali_carousel',
        'component': 'TravelCarousel',
        'items': [
          {
            'imageChildId': 'bali_memorial_image',
            'description': 'Cultural Immersion',
            'action': {'name': 'selectExperience'},
          },
          {
            'imageChildId': 'nyepi_festival_image',
            'description': 'Festivals and Traditions',
            'action': {'name': 'selectExperience'},
          },
          {
            'imageChildId': 'kata_noi_beach_image',
            'description': 'Beach Relaxation',
            'action': {'name': 'selectExperience'},
          },
        ],
      },
      {
        'id': 'bali_memorial_image',
        'component': 'Image',
        'fit': 'cover',
        'url': 'assets/travel_images/bali_memorial.jpg',
      },
      {
        'id': 'nyepi_festival_image',
        'component': 'Image',
        'fit': 'cover',
        'url': 'assets/travel_images/nyepi_festival_bali.jpg',
      },
      {
        'id': 'kata_noi_beach_image',
        'component': 'Image',
        'fit': 'cover',
        'url': 'assets/travel_images/kata_noi_beach_phuket_thailand.jpg',
      },
      {
        'id': 'trip_filters',
        'component': 'InputGroup',
        'submitLabel': 'Plan My Trip',
        'children': ['travel_style_chip', 'budget_chip', 'duration_chip'],
        'action': {'name': 'plan_trip'},
      },
      {
        'id': 'travel_style_chip',
        'component': 'OptionsFilterChipInput',
        'iconName': 'location',
        'options': [
          'Relaxation',
          'Adventure',
          'Culture',
          'Family Fun',
          'Romantic Getaway',
        ],
        'chipLabel': 'Travel Style',
      },
      {
        'id': 'budget_chip',
        'component': 'OptionsFilterChipInput',
        'options': ['Economy', 'Mid-range', 'Luxury'],
        'iconName': 'wallet',
        'chipLabel': 'Budget',
      },
      {
        'id': 'duration_chip',
        'component': 'OptionsFilterChipInput',
        'chipLabel': 'Duration',
        'options': ['3-5 Days', '1 Week', '10+ Days'],
        'iconName': 'calendar',
      },
    ],
  },
};
