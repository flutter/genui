import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  properties: {
    'title': Schema.string(description: 'The title of the itinerary item.'),
    'subtitle': Schema.string(
      description: 'The subtitle of the itinerary item.',
    ),
    'thumbnailUrl': Schema.string(
      description: 'The URL of the thumbnail image.',
    ),
    'detailText': Schema.string(description: 'The detail text for the item.'),
  },
);

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
        final title = (data as Map)['title'] as String;
        final subtitle = data['subtitle'] as String;
        final thumbnailUrl = data['thumbnailUrl'] as String;
        final detailText = data['detailText'] as String;

        return _ItineraryItem(
          title: title,
          subtitle: subtitle,
          thumbnailUrl: thumbnailUrl,
          detailText: detailText,
        );
      },
);

class _ItineraryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final String detailText;

  const _ItineraryItem({
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
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
            child: Image.network(
              thumbnailUrl,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image, size: 80),
            ),
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
