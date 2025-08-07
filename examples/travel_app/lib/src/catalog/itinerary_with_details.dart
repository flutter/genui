// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'itinerary_item.dart';
library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  description:
      'Widget to show an itinerary or a plan for travel. Use this only for '
      'refined plans where you have already shown the user filter options '
      'etc.',
  properties: {
    'title': S.string(description: 'The title of the itinerary.'),
    'subheading': S.string(description: 'The subheading of the itinerary.'),
    'imageChild': S.string(
      description:
          'The ID of the image widget to display. The image fit should '
          "typically be 'cover'",
    ),
    'child': S.string(
      description:
          '''The ID of a child widget to display in a modal. This should typically be a column which contains a sequence of itinerary_items, text, travel_carousel etc. Most of the content should be the trip details shown in itinerary_items, but try to break it up with other elements showing related content. If there are multiple sections to the itinerary, you can use the tabbed_sections to break them up.''',
    ),
  },
  required: ['title', 'subheading', 'imageChild', 'child'],
);

extension type _ItineraryWithDetailsData.fromMap(Map<String, Object?> _json) {
  factory _ItineraryWithDetailsData({
    required String title,
    required String subheading,
    required String imageChild,
    required String child,
  }) => _ItineraryWithDetailsData.fromMap({
    'title': title,
    'subheading': subheading,
    'imageChild': imageChild,
    'child': child,
  });

  String get title => _json['title'] as String;
  String get subheading => _json['subheading'] as String;
  String get imageChild => _json['imageChild'] as String;
  String get child => _json['child'] as String;
}

/// A high-level summary card that represents a complete travel itinerary.
///
/// This widget is intended to be used as a primary result after a user has
/// refined their search criteria. It displays a title, subheading, and a
/// prominent image to give the user a quick overview of the proposed trip.
///
/// When tapped, it presents a modal bottom sheet containing the detailed
/// breakdown of the itinerary, which is typically composed of a `Column` of
/// [itineraryItem] widgets and other supplemental content.
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
        final itineraryWithDetailsData = _ItineraryWithDetailsData.fromMap(
          data as Map<String, Object?>,
        );
        final child = buildChild(itineraryWithDetailsData.child);
        final imageChild = buildChild(itineraryWithDetailsData.imageChild);

        return _ItineraryWithDetails(
          title: itineraryWithDetailsData.title,
          subheading: itineraryWithDetailsData.subheading,
          imageChild: imageChild,
          child: child,
        );
      },
);

class _ItineraryWithDetails extends StatelessWidget {
  final String title;
  final String subheading;
  final Widget imageChild;
  final Widget child;

  const _ItineraryWithDetails({
    required this.title,
    required this.subheading,
    required this.imageChild,
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
                      SizedBox(
                        width: double.infinity,
                        height: 200, // You can adjust this height as needed
                        child: imageChild,
                      ),
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      child,
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
              child: SizedBox(height: 100, width: 100, child: imageChild),
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
