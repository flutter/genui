import 'package:example/sdk/model/simple_items.dart';
import 'package:flutter/material.dart';

class Carousel extends StatelessWidget {
  const Carousel({super.key, required this.data});

  final CarouselData data;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.items.length,
        itemBuilder: (context, index) => CarouselItem(data: data.items[index]),
      ),
    );
  }
}

class CarouselItem extends StatelessWidget {
  final CarouselItemData data;

  const CarouselItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class CarouselItemData extends WidgetData {
  final String title;
  final String imageUrl;

  CarouselItemData({required this.title, required this.imageUrl});
}

class CarouselData extends WidgetData {
  final List<CarouselItemData> items;

  CarouselData({required this.items});
}
