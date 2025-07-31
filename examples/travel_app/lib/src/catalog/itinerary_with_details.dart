import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  description: 'Widget to show an itinerary or a plan for travel.',
  properties: {
    'title': Schema.string(description: 'The title of the itinerary.'),
    'subheading': Schema.string(
      description: 'The subheading of the itinerary.',
    ),
    'thumbnailUrl': Schema.string(
      description: 'The URL of the thumbnail image.',
    ),
    'child': Schema.string(
      description:
          '''The ID of a child widget to display in a modal. This should typically be a column which contains a sequence of itinerary_items, text, travel_carousel etc. Most of the content should be the trip details shown in itinerary_items, but try to break it up with other elements showing related content. If there are multiple sections to the itinerary, you can use the tabbed_sections to break them up.''',
    ),
  },
);

final itineraryWithDetails = CatalogItem(
  name: 'itinerary_with_details',
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
        final subheading = data['subheading'] as String;
        final thumbnailUrl = data['thumbnailUrl'] as String;
        final childId = data['child'] as String;
        final child = buildChild(childId);

        return _ItineraryWithDetails(
          title: title,
          subheading: subheading,
          thumbnailUrl: thumbnailUrl,
          child: child,
        );
      },
);

class _ItineraryWithDetails extends StatelessWidget {
  final String title;
  final String subheading;
  final String thumbnailUrl;
  final Widget child;

  const _ItineraryWithDetails({
    required this.title,
    required this.subheading,
    required this.thumbnailUrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          builder: (BuildContext context) {
            return FractionallySizedBox(
              heightFactor: 0.9,
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Image.network(
                            thumbnailUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            height: 200, // You can adjust this height as needed
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, size: 200),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16.0),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16.0),
                            child,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Card(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                8.0,
              ), // Adjust radius as needed
              child: Image.network(
                thumbnailUrl,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                    subheading,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
