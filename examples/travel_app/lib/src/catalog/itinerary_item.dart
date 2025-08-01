import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  properties: {
    'title': Schema.string(description: 'The title of the itinerary item.'),
    'subtitle': Schema.string(
      description: 'The subtitle of the itinerary item.',
    ),
    'imageChild': Schema.string(
      description:
          'The ID of the image widget to display. The image fit should '
          "typically be 'cover'",
    ),
    'detailText': Schema.string(description: 'The detail text for the item.'),
  },
);

extension type _ItineraryItemData.fromMap(Map<String, Object?> _json) {
  factory _ItineraryItemData({
    required String title,
    required String subtitle,
    required String imageChild,
    required String detailText,
  }) => _ItineraryItemData.fromMap({
    'title': title,
    'subtitle': subtitle,
    'imageChild': imageChild,
    'detailText': detailText,
  });

  String get title => _json['title'] as String;
  String get subtitle => _json['subtitle'] as String;
  String get imageChild => _json['imageChild'] as String;
  String get detailText => _json['detailText'] as String;
}

final itineraryItem = CatalogItem(
  name: 'itinerary_item',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final itineraryItemData = _ItineraryItemData.fromMap(
          data as Map<String, Object?>,
        );
        return _ItineraryItem(
          title: itineraryItemData.title,
          subtitle: itineraryItemData.subtitle,
          imageChild: buildChild(itineraryItemData.imageChild),
          detailText: itineraryItemData.detailText,
        );
      },
);

class _ItineraryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget imageChild;
  final String detailText;

  const _ItineraryItem({
    required this.title,
    required this.subtitle,
    required this.imageChild,
    required this.detailText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(height: 80, width: 80, child: imageChild),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4.0),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8.0),
                Text(detailText, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
