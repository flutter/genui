// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'itinerary_with_details.dart';
library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../utils.dart';

final _schema = S.object(
  description:
      'A container for a single day in an itinerary. '
      'It should contain a list of ItineraryEntry widgets. '
      'This should be nested inside an ItineraryWithDetails.',
  properties: {
    'title': S.string(description: 'The title for the day, e.g., "Day 1".'),
    'subtitle': S.string(
      description: 'The subtitle for the day, e.g., "Arrival in Tokyo".',
    ),
    'description': S.string(
      description:
          'A short description of the day\'s plan. This supports markdown.',
    ),
    'imageChildId': S.string(
      description:
          'The ID of the Image widget to display. The Image fit should '
          'typically be \'cover\'.',
    ),
    'children': S.list(
      description:
          'A list of widget IDs for the ItineraryEntry children for this day.',
      items: S.string(),
    ),
  },
  required: ['title', 'subtitle', 'description', 'imageChildId', 'children'],
);

extension type _ItineraryDayData.fromMap(Map<String, Object?> _json) {
  factory _ItineraryDayData({
    required String title,
    required String subtitle,
    required String description,
    required String imageChildId,
    required List<String> children,
  }) => _ItineraryDayData.fromMap({
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'imageChildId': imageChildId,
    'children': children,
  });

  String get title => _json['title'] as String;
  String get subtitle => _json['subtitle'] as String;
  String get description => _json['description'] as String;
  String get imageChildId => _json['imageChildId'] as String;
  List<String> get children => (_json['children'] as List).cast<String>();
}

final itineraryDay = CatalogItem(
  name: 'ItineraryDay',
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
        final itineraryDayData = _ItineraryDayData.fromMap(
          data as Map<String, Object?>,
        );
        return _ItineraryDay(
          title: itineraryDayData.title,
          subtitle: itineraryDayData.subtitle,
          description: itineraryDayData.description,
          imageChild: buildChild(itineraryDayData.imageChildId),
          children: itineraryDayData.children.map(buildChild).toList(),
        );
      },
);

class _ItineraryDay extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final Widget imageChild;
  final List<Widget> children;

  const _ItineraryDay({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageChild,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      Text(title, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4.0),
                      Text(subtitle, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            MarkdownBody(
              data: description,
              styleSheet: getMarkdownStyleSheet(context),
            ),
            const SizedBox(height: 8.0),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}
