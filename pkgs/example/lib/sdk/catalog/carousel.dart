import 'package:example/sdk/catalog/shared/text_styles.dart';
import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

const double _imageSize = 190;

class Carousel extends StatelessWidget {
  const Carousel({super.key, required this.data});

  final CarouselData data;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: CarouselView(
        itemExtent: _imageSize,
        // Set no border.
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        children: data.items.map((item) => CarouselItem(data: item)).toList(),
      ),
    );
  }
}

class CarouselItem extends StatelessWidget {
  final CarouselItemData data;

  const CarouselItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: _imageSize,
          height: _imageSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.asset(data.assetUrl, fit: BoxFit.cover),
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
