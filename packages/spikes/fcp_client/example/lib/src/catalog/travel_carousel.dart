// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';

class TravelCarousel extends StatelessWidget {
  const TravelCarousel({super.key, required this.items});

  final List<TravelCarouselItemData> items;

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
            return _TravelCarouselItem(data: items[index]);
          },
          separatorBuilder: (context, index) => const SizedBox(width: 16),
        ),
      ),
    );
  }
}

class _DesktopAndWebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class TravelCarouselItemData {
  final String title;
  final Widget imageChild;

  TravelCarouselItemData({required this.title, required this.imageChild});
}

class _TravelCarouselItem extends StatefulWidget {
  const _TravelCarouselItem({required this.data});

  final TravelCarouselItemData data;

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
        FcpProvider.of(context)?.onEvent?.call(
          EventPayload(
            sourceNodeId: 'travel_carousel',
            eventName: 'itemSelected',
            arguments: {'value': widget.data.title},
          ),
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
                  child: widget.data.imageChild,
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
