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
          'photoUrl': Schema.string(
            description: 'The URL of the photo to display.',
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
          items: items.toList(),
          widgetId: id,
          dispatchEvent: dispatchEvent,
        );
      },
);

extension type _TravelCarouselItemListData.fromMap(Map<String, Object?> _json) {
  factory _TravelCarouselItemListData({
    required List<Map<String, Object>> items,
  }) => _TravelCarouselItemListData.fromMap({'items': items});

  Iterable<_TravelCarouselItemData> get items => (_json['items'] as List)
      .cast<Map<String, Object?>>()
      .map<_TravelCarouselItemData>(_TravelCarouselItemData.fromMap);
}

extension type _TravelCarouselItemData.fromMap(Map<String, Object?> _json) {
  factory _TravelCarouselItemData({
    required String title,
    required String photoUrl,
  }) => _TravelCarouselItemData.fromMap({'title': title, 'photoUrl': photoUrl});

  String get title => _json['title'] as String;
  String get photoUrl => _json['photoUrl'] as String;
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

class _TravelCarouselItem extends StatefulWidget {
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
  State<_TravelCarouselItem> createState() => _TravelCarouselItemState();
}

class _TravelCarouselItemState extends State<_TravelCarouselItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      onTap: () {
        widget.dispatchEvent(
          widgetId: widget.widgetId,
          eventType: 'itemSelected',
          value: widget.data.title,
        );
      },
      child: SizedBox(
        width: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _isPressed
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.transparent,
                  BlendMode.darken,
                ),
                child: SizedBox(
                  height: 150,
                  width: 190,
                  child: Image.network(widget.data.photoUrl, fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.data.title,
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
