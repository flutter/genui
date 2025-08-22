// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  properties: {
    'items': S.list(
      description: 'A list of items to display in the carousel.',
      items: S.object(
        properties: {
          'title': S.string(description: 'The title of the carousel item.'),
          'imageChildId': S.string(
            description:
                'The ID of the Image widget to display as the carousel item '
                'image. Be sure to create Image widgets with matching IDs.',
          ),
        },
        required: ['title', 'imageChildId'],
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
      }) {
        final items = _TravelCarouselItemListData.fromMap(
          (data as Map).cast<String, Object?>(),
        ).items;
        return _TravelCarousel(
          items: items
              .map(
                (e) => _TravelCarouselItemData(
                  title: e.title,
                  imageChild: buildChild(e.imageChildId),
                ),
              )
              .toList(),
          widgetId: id,
          dispatchEvent: dispatchEvent,
        );
      },
);

extension type _TravelCarouselItemListData.fromMap(Map<String, Object?> _json) {
  factory _TravelCarouselItemListData({
    required List<Map<String, Object>> items,
  }) => _TravelCarouselItemListData.fromMap({'items': items});

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
    required String title,
    required String imageChildId,
  }) => _TravelCarouselItemSchemaData.fromMap({
    'title': title,
    'imageChildId': imageChildId,
  });

  String get title => _json['title'] as String;
  String get imageChildId => _json['imageChildId'] as String;
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
    required this.items,
    required this.widgetId,
    required this.dispatchEvent,
  });

  final List<_TravelCarouselItemData> items;
  final String widgetId;
  final DispatchEventCallback dispatchEvent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
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
    );
  }
}

class _TravelCarouselItemData {
  final String title;
  final Widget imageChild;

  _TravelCarouselItemData({required this.title, required this.imageChild});
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
              value: data.title,
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                data.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
