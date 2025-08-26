// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'itinerary_with_details.dart';
library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  properties: {
    'title': S.string(description: 'The title of the itinerary item.'),
    'subtitle': S.string(description: 'The subtitle of the itinerary item.'),
    'imageChildId': S.string(
      description:
          'The ID of the Image widget to display. The Image fit should '
          "typically be 'cover'.  Be sure to create an Image widget with a "
          'matching ID.',
    ),
    'detailText': S.string(description: 'The detail text for the item.'),
  },
  required: ['title', 'subtitle', 'detailText'],
);

extension type _ItineraryItemData.fromMap(Map<String, Object?> _json) {
  factory _ItineraryItemData({
    required String title,
    required String subtitle,
    String? imageChildId,
    required String detailText,
  }) => _ItineraryItemData.fromMap({
    'title': title,
    'subtitle': subtitle,
    'imageChildId': imageChildId,
    'detailText': detailText,
  });

  String get title => _json['title'] as String;
  String get subtitle => _json['subtitle'] as String;
  String? get imageChildId => _json['imageChildId'] as String?;
  String get detailText => _json['detailText'] as String;
}

/// A widget that displays a single, distinct event or activity within a larger
/// travel plan.
///
/// It serves as a fundamental building block for creating detailed,
/// step-by-step travel itineraries. Each [itineraryItem] typically includes a
/// title, a subtitle (for time or location), an optional image, and a block of
/// text for details.
///
/// These are most often used in a `Column` within a modal view that is launched
/// from an [itineraryWithDetails] widget, where a sequence of these items can
/// represent a full day's schedule or a list of activities.
final itineraryItem = CatalogItem(
  name: 'ItineraryItem',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final itineraryItemData = _ItineraryItemData.fromMap(
          data as Map<String, Object?>,
        );
        return _ItineraryItem(
          title: itineraryItemData.title,
          subtitle: itineraryItemData.subtitle,
          imageChild: itineraryItemData.imageChildId != null
              ? buildChild(itineraryItemData.imageChildId!)
              : null,
          detailText: itineraryItemData.detailText,
        );
      },
);

class _ItineraryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? imageChild;
  final String detailText;

  const _ItineraryItem({
    required this.title,
    required this.subtitle,
    required this.imageChild,
    required this.detailText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
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
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4.0),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8.0),
                  Text(detailText, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
