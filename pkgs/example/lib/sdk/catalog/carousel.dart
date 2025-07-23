import 'package:flutter/material.dart';

class Carousel extends StatelessWidget {
  const Carousel({super.key, required this.data});

  final List<CarouselItemData> data;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) => CarouselItem(data: data[index]),
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

class CarouselItemData {
  final String title;
  final String imageUrl;

  CarouselItemData({required this.title, required this.imageUrl});
}
