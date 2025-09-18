// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'itinerary_day.dart';
/// @docImport 'itinerary_entry.dart';
library;

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  description: 'A widget to break up sections of a longer list of content.',
  properties: {
    'title': S.string(description: 'The title of the section.'),
    'subtitle': S.string(description: 'The subtitle of the section.'),
  },
  required: ['title'],
);

extension type _SectionHeaderData.fromMap(Map<String, Object?> _json) {
  factory _SectionHeaderData({required String title, String? subtitle}) =>
      _SectionHeaderData.fromMap({'title': title, 'subtitle': subtitle});

  String get title => _json['title'] as String;
  String? get subtitle => _json['subtitle'] as String?;
}

/// A presentational widget used to create visual and thematic separation within
/// a list of content.
///
/// It displays a prominent title and an optional subtitle, helping to organize
/// longer sequences of widgets, such as a detailed travel itinerary composed of
/// multiple [itineraryDay] widgets. Its primary role is to improve the
/// structure and scannability of the UI.
final sectionHeader = CatalogItem(
  name: 'SectionHeader',
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
        final sectionHeaderData = _SectionHeaderData.fromMap(
          data as Map<String, Object?>,
        );

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectionHeaderData.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (sectionHeaderData.subtitle != null)
                Text(
                  sectionHeaderData.subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
            ],
          ),
        );
      },
);
