// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import '../tools/booking/booking_service.dart';
import '../tools/booking/model.dart';

final _schema = S.object(
  properties: {
    'title': S.string(
      description: 'An optional title to display above the carousel.',
    ),
    'items': S.list(
      description: 'A list of items to display in the carousel.',
      items: S.object(
        properties: {
          'description': S.string(
            description:
                'The short description of the carousel item. '
                'It may include the price and location if applicable. '
                'It should be very concise. '
                'Example: "The Dart Inn in Sunnyvale, CA for \$150"',
          ),
          'imageChildId': S.string(
            description:
                'The ID of the Image widget to display as the carousel item '
                'image. Be sure to create Image widgets with matching IDs.',
          ),
          'listingSelectionId': S.string(
            description:
                'An optional ID of the listing that this item '
                'represents. This is useful when the carousel is used to show '
                'a list of hotels or other bookable items.',
          ),
        },
        required: ['description', 'imageChildId'],
      ),
    ),
  },
  required: ['items'],
);

/// A widget that presents a horizontally scrolling list of tappable items, each
/// with an image and a title.
///
/// This component is ideal for showcasing a set of options to the user in a
/// visually engaging way, such as potential destinations, activities, or tours.
/// It is often used by the AI in the initial stages of a conversation to help
/// narrow down the user's preferences. When an item is tapped, it dispatches an
/// event with the item's title, allowing the AI to respond to the user's
/// selection.
final travelCarousel = CatalogItem(
  name: 'TravelCarousel',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final carouselData = _TravelCarouselData.fromMap(
          (data as Map).cast<String, Object?>(),
        );
        final items = carouselData.items;
        return _TravelCarousel(
          title: carouselData.title,
          items: items
              .map(
                (e) => _TravelCarouselItemData(
                  description: e.description,
                  imageChild: buildChild(e.imageChildId),
                  listingSelectionId: e.listingSelectionId,
                ),
              )
              .toList(),
          widgetId: id,
          dispatchEvent: dispatchEvent,
        );
      },
  exampleData: [_inspirationExample, _hotelExample],
);

extension type _TravelCarouselData.fromMap(Map<String, Object?> _json) {
  factory _TravelCarouselData({
    String? title,
    required List<Map<String, Object>> items,
  }) => _TravelCarouselData.fromMap({
    if (title != null) 'title': title,
    'items': items,
  });

  String? get title => _json['title'] as String?;
  Iterable<_TravelCarouselItemSchemaData> get items => (_json['items'] as List)
      .cast<Map<String, Object?>>()
      .map<_TravelCarouselItemSchemaData>(
        _TravelCarouselItemSchemaData.fromMap,
      );
}

extension type _TravelCarouselItemSchemaData.fromMap(
  Map<String, Object?> _json
) {
  factory _TravelCarouselItemSchemaData({
    required String description,
    required String imageChildId,
    String? listingSelectionId,
  }) => _TravelCarouselItemSchemaData.fromMap({
    'description': description,
    'imageChildId': imageChildId,
    if (listingSelectionId != null) 'listingSelectionId': listingSelectionId,
  });

  String get description => _json['description'] as String;
  String get imageChildId => _json['imageChildId'] as String;
  String? get listingSelectionId => _json['listingSelectionId'] as String?;
}

class _DesktopAndWebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class _TravelCarousel extends StatelessWidget {
  const _TravelCarousel({
    this.title,
    required this.items,
    required this.widgetId,
    required this.dispatchEvent,
  });

  final String? title;
  final List<_TravelCarouselItemData> items;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16.0),
        ],
        SizedBox(
          height: 240,
          child: ScrollConfiguration(
            behavior: _DesktopAndWebScrollBehavior(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _TravelCarouselItem(
                  data: items[index],
                  widgetId: widgetId,
                  dispatchEvent: dispatchEvent,
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _TravelCarouselItemData {
  final String description;
  final Widget imageChild;
  final String? listingSelectionId;

  _TravelCarouselItemData({
    required this.description,
    required this.imageChild,
    this.listingSelectionId,
  });
}

class _TravelCarouselItem extends StatelessWidget {
  const _TravelCarouselItem({
    required this.data,
    required this.widgetId,
    required this.dispatchEvent,
  });

  final _TravelCarouselItemData data;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: InkWell(
        onTap: () {
          dispatchEvent(
            UiActionEvent(
              widgetId: widgetId,
              eventType: 'itemSelected',
              value: {
                'description': data.description,
                if (data.listingSelectionId != null)
                  'listingSelectionId': data.listingSelectionId,
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: SizedBox(height: 150, width: 190, child: data.imageChild),
            ),
            Container(
              height: 90,
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

JsonMap _hotelExample() {
  final hotels = BookingService.instance.listHotelsSync(
    HotelSearch(
      query: '',
      checkIn: DateTime.now(),
      checkOut: DateTime.now().add(const Duration(days: 7)),
      guests: 2,
    ),
  );
  final hotel1 = hotels.listings[0];
  final hotel2 = hotels.listings[1];

  return {
    'root': 'hotel_carousel',
    'widgets': [
      {
        'widget': {
          'TravelCarousel': {
            'items': [
              {
                'description': hotel1.description,
                'imageChildId': 'image_1',
                'listingSelectionId': '12345',
              },
              {
                'description': hotel2.description,
                'imageChildId': 'image_2',
                'listingSelectionId': '12346',
              },
            ],
          },
        },
        'id': 'hotel_carousel',
      },
      {
        'id': 'image_1',
        'widget': {
          'Image': {'fit': 'cover', 'location': hotel1.images[0]},
        },
      },
      {
        'id': 'image_2',
        'widget': {
          'Image': {'fit': 'cover', 'location': hotel2.images[0]},
        },
      },
    ],
  };
}

JsonMap _inspirationExample() => {
  'root': 'greece_inspiration_column',
  'widgets': [
    {
      'id': 'greece_inspiration_column',
      'widget': {
        'Column': {
          'children': ['inspiration_title', 'inspiration_carousel'],
        },
      },
    },
    {
      'id': 'inspiration_title',
      'widget': {
        'Text': {
          'text':
              "Let's plan your dream trip to Greece! "
              'What kind of experience'
              ' are you looking for?',
        },
      },
    },
    {
      'widget': {
        'TravelCarousel': {
          'items': [
            {
              'description': 'Relaxing Beach Holiday',
              'imageChildId': 'santorini_beach_image',
              'listingSelectionId': '12345',
            },
            {
              'imageChildId': 'akrotiri_fresco_image',
              'description': 'Cultural Exploration',
              'listingSelectionId': '12346',
            },
            {
              'imageChildId': 'santorini_caldera_image',
              'description': 'Adventure & Outdoors',
              'listingSelectionId': '12347',
            },
            {'description': 'Foodie Tour', 'imageChildId': 'greece_food_image'},
          ],
        },
      },
      'id': 'inspiration_carousel',
    },
    {
      'id': 'santorini_beach_image',
      'widget': {
        'Image': {
          'fit': 'cover',
          'location': 'assets/travel_images/santorini_panorama.jpg',
        },
      },
    },
    {
      'id': 'akrotiri_fresco_image',
      'widget': {
        'Image': {
          'fit': 'cover',
          'location':
              'assets/travel_images/akrotiri_spring_fresco_santorini.jpg',
        },
      },
    },
    {
      'id': 'santorini_caldera_image',
      'widget': {
        'Image': {
          'location': 'assets/travel_images/santorini_from_space.jpg',
          'fit': 'cover',
        },
      },
    },
    {
      'widget': {
        'Image': {
          'fit': 'cover',
          'location':
              'assets/travel_images/saffron_gatherers_fresco_santorini.jpg',
        },
      },
      'id': 'greece_food_image',
    },
  ],
};
