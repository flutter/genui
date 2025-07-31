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
          'title':
              Schema.string(description: 'The title of the carousel item.'),
          'photoUrl':
              Schema.string(description: 'The URL of the photo to display.'),
        },
      ),
    ),
  },
);

final travelCarousel = CatalogItem(
  name: 'travelCarousel',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
  }) {
    final items = (data['items'] as List)
        .map((item) => _TravelCarouselItemData(
              title: item['title'] as String,
              photoUrl: item['photoUrl'] as String,
            ))
        .toList();
    return _TravelCarousel(
      items: items,
      widgetId: id,
      dispatchEvent: dispatchEvent,
    );
  },
);

class _TravelCarouselItemData {
  final String title;
  final String photoUrl;

  _TravelCarouselItemData({required this.title, required this.photoUrl});
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
  }) dispatchEvent;

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
  }) dispatchEvent;

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
                      ? Colors.black.withOpacity(0.4)
                      : Colors.transparent,
                  BlendMode.darken,
                ),
                child: SizedBox(
                  height: 150,
                  width: 190,
                  child: Image.network(
                    widget.data.photoUrl,
                    fit: BoxFit.cover,
                  ),
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
