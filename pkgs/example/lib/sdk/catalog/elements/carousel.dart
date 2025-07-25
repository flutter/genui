import 'package:flutter/material.dart';

import '../../model/simple_items.dart';
import '../shared/text_styles.dart';

const double _imageSize = 190;

class Carousel extends StatelessWidget {
  const Carousel(this.data, {super.key});

  final CarouselData data;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: CarouselView(
        itemExtent: _imageSize,
        // Set no border.
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        children: data.items.map(CarouselItem.new).toList(),
      ),
    );
  }
}

class CarouselItem extends StatelessWidget {
  final CarouselItemData data;

  const CarouselItem(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: _imageSize,
          height: _imageSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
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
