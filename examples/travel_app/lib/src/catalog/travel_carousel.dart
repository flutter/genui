import 'dart:ui';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  properties: {
    'items': Schema.array(
      description: 'A list of items to display in the carousel.',
      items: Schema.object(
        properties: {
          'title': Schema.string(
            description: 'The title of the carousel item.',
          ),
          'imageChild': Schema.string(
            description:
                'The ID of the image widget to display. The image fit should '
                'typically be \'cover\'',
          ),
        },
      ),
    ),
  },
);

final travelCarousel = CatalogItem(
  name: 'travelCarousel',
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
                  imageChild: buildChild(e.imageChild),
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
    required String imageChild,
  }) => _TravelCarouselItemSchemaData.fromMap({
    'title': title,
    'imageChild': imageChild,
  });

  String get title => _json['title'] as String;
  String get imageChild => _json['imageChild'] as String;
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
  final void Function({
    required String widgetId,
    required String eventType,
    required Object? value,
  })
  dispatchEvent;

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
  final void Function({
    required String widgetId,
    required String eventType,
    required Object? value,
  })
  dispatchEvent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: InkWell(
        onTap: () {
          dispatchEvent(
            widgetId: widgetId,
            eventType: 'itemSelected',
            value: data.title,
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
