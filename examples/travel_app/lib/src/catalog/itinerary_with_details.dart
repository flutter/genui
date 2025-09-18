// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'itinerary_entry.dart';
library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import '../widgets/dismiss_notification.dart';

final _schema = S.object(
  description:
      'Widget to show an itinerary or a plan for travel. This should contain '
      'a list of ItineraryDay widgets.',
  properties: {
    'title': S.string(description: 'The title of the itinerary.'),
    'subheading': S.string(description: 'The subheading of the itinerary.'),
    'imageChildId': S.string(
      description:
          'The ID of the Image widget to display. The Image fit '
          "should typically be 'cover'. Be sure to create an Image widget "
          'with a matching ID.',
    ),
    'child': S.string(
      description:
          'The ID of a child widget to display in a modal. This should '
          'typically be a Column which contains a sequence of ItineraryDays.',
    ),
  },
  required: ['title', 'subheading', 'imageChildId', 'child'],
);

extension type _ItineraryWithDetailsData.fromMap(Map<String, Object?> _json) {
  factory _ItineraryWithDetailsData({
    required String title,
    required String subheading,
    required String imageChildId,
    required String child,
  }) => _ItineraryWithDetailsData.fromMap({
    'title': title,
    'subheading': subheading,
    'imageChildId': imageChildId,
    'child': child,
  });

  String get title => _json['title'] as String;
  String get subheading => _json['subheading'] as String;
  String get imageChildId => _json['imageChildId'] as String;
  String get child => _json['child'] as String;
}

/// A high-level summary card that represents a complete travel itinerary.
///
/// This widget is intended to be used as a primary result after a user has
/// refined their search criteria. It displays a title, subheading, and a
/// prominent image to give the user a quick overview of the proposed trip.
///
/// When tapped, it presents a modal bottom sheet containing the detailed
/// breakdown of the itinerary.
final itineraryWithDetails = CatalogItem(
  name: 'ItineraryWithDetails',
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
        final itineraryWithDetailsData = _ItineraryWithDetailsData.fromMap(
          data as Map<String, Object?>,
        );
        final child = buildChild(itineraryWithDetailsData.child);
        final imageChild = buildChild(itineraryWithDetailsData.imageChildId);

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
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return NotificationListener<DismissNotification>(
              onNotification: (notification) {
                Navigator.of(context).pop();
                return true;
              },
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: Scaffold(
                  body: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height:
                                  200, // You can adjust this height as needed
                              child: imageChild,
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            child,
                          ],
                        ),
                      ),
                      Positioned(
                        top: 16.0,
                        right: 16.0,
                        child: Material(
                          color: Colors.white.withAlpha((255 * 0.8).round()),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
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
