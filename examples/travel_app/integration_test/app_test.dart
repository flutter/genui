// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Initial UI test', () {
    testWidgets('send a request and verify the UI', (tester) async {
      final mockAiClient = FakeAiClient();
      mockAiClient.response = _baliResponse;

      runApp(app.TravelApp(aiClient: mockAiClient));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Plan a trip to Bali');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(
        find.text(
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

const Map<String, Object> _baliResponse = {
  'actions': [
    {
      'action': 'add',
      'surfaceId': 'bali_trip_planning_intro',
      'definition': {
        'root': 'main_column',
        'widgets': [
          {
            'id': 'main_column',
            'widget': {
              'Column': {
                'children': ['welcome_text', 'bali_carousel', 'trip_filters'],
                'spacing': 16,
                'crossAxisAlignment': 'start',
                'mainAxisAlignment': 'start',
              },
            },
          },
          {
            'widget': {
              'Text': {
                'text':
                    'Great! I can help you plan a fantastic trip to Bali. To '
                    'get started, what kind of experience are you looking for?',
              },
            },
            'id': 'welcome_text',
          },
          {
            'id': 'bali_carousel',
            'widget': {
              'TravelCarousel': {
                'items': [
                  {
                    'imageChildId': 'bali_memorial_image',
                    'title': 'Cultural Immersion',
                  },
                  {
                    'imageChildId': 'nyepi_festival_image',
                    'title': 'Festivals and Traditions',
                  },
                  {
                    'title': 'Beach Relaxation',
                    'imageChildId': 'kata_noi_beach_image',
                  },
                ],
              },
            },
          },
          {
            'id': 'bali_memorial_image',
            'widget': {
              'Image': {
                'fit': 'cover',
                'location': 'assets/travel_images/bali_memorial.jpg',
              },
            },
          },
          {
            'id': 'nyepi_festival_image',
            'widget': {
              'Image': {
                'fit': 'cover',
                'location': 'assets/travel_images/nyepi_festival_bali.jpg',
              },
            },
          },
          {
            'id': 'kata_noi_beach_image',
            'widget': {
              'Image': {
                'fit': 'cover',
                'location':
                    'assets/travel_images/kata_noi_beach_phuket_thailand.jpg',
              },
            },
          },
          {
            'widget': {
              'FilterChipGroup': {
                'submitLabel': 'Plan My Trip',
                'children': [
                  'travel_style_chip',
                  'budget_chip',
                  'duration_chip',
                ],
              },
            },
            'id': 'trip_filters',
          },
          {
            'widget': {
              'OptionsFilterChip': {
                'iconChild': 'travel_icon_hiking',
                'options': [
                  'Relaxation',
                  'Adventure',
                  'Culture',
                  'Family Fun',
                  'Romantic Getaway',
                ],
                'chipLabel': 'Travel Style',
              },
            },
            'id': 'travel_style_chip',
          },
          {
            'widget': {
              'TravelIcon': {'icon': 'hiking'},
            },
            'id': 'travel_icon_hiking',
          },
          {
            'widget': {
              'OptionsFilterChip': {
                'options': ['Economy', 'Mid-range', 'Luxury'],
                'iconChild': 'travel_icon_wallet',
                'chipLabel': 'Budget',
              },
            },
            'id': 'budget_chip',
          },
          {
            'id': 'travel_icon_wallet',
            'widget': {
              'TravelIcon': {'icon': 'wallet'},
            },
          },
          {
            'id': 'duration_chip',
            'widget': {
              'OptionsFilterChip': {
                'chipLabel': 'Duration',
                'options': ['3-5 Days', '1 Week', '10+ Days'],
                'iconChild': 'travel_icon_calendar',
              },
            },
          },
          {
            'widget': {
              'TravelIcon': {'icon': 'calendar'},
            },
            'id': 'travel_icon_calendar',
          },
        ],
      },
    },
  ],
};
