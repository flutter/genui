// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/input.dart';
import '../../model/simple_items.dart';
import '../shared/text_styles.dart';

const double _imageSize = 190;

class Carousel extends StatelessWidget {
  const Carousel(this.data, this.onInput, {super.key});

  final CarouselData data;
  final UserInputCallback onInput;

  @override
  Widget build(BuildContext context) {
    const padding = 8.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: CarouselView(
        itemExtent: _imageSize,
        padding: const EdgeInsets.symmetric(horizontal: padding),
        // Set no border.
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        // TODO(polina-c): Handle the case where item are cut.
        // https://stackoverflow.com/questions/79714971/how-to-crop-last-image-in-carousel-without-rounded-corners
        children: data.items.map(CarouselItem.new).toList(),
      ),
    );
  }
}

class CarouselItem extends StatelessWidget {
  final CarouselItemData data;
  final bool isCutOnRight;
  final bool isCutOnLeft;

  const CarouselItem(
    this.data, {
    super.key,
    this.isCutOnRight = false,
    this.isCutOnLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(10.0);
    final borderRadius = BorderRadius.horizontal(
      left: isCutOnLeft ? Radius.zero : radius,
      right: isCutOnRight ? Radius.zero : radius,
    );

    return Column(
      children: [
        Container(
          width: _imageSize,
          height: _imageSize,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Image.asset(
              data.assetUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topLeft,
            ),
          ),
        ),
        Text(
          data.title,
          style: GenUiTextStyles.normal(context),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class CarouselItemData extends WidgetData {
  final String title;
  final String assetUrl;

  CarouselItemData({required this.title, required this.assetUrl});
}

class CarouselData extends WidgetData {
  final List<CarouselItemData> items;

  CarouselData({required this.items});
}
