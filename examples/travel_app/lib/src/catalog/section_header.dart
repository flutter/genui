// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'itinerary_day.dart';
/// @docImport 'itinerary_entry.dart';
library;

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final _schema = S.object(
  description: 'A widget to break up sections of a longer list of content.',
  properties: {
    'title': A2uiSchemas.stringReference(
      description: 'The title of the section.',
    ),
    'subtitle': A2uiSchemas.stringReference(
      description: 'The subtitle of the section.',
    ),
  },
  required: ['title'],
);

extension type _SectionHeaderData.fromMap(Map<String, Object?> _json) {
  factory _SectionHeaderData({required JsonMap title, JsonMap? subtitle}) =>
      _SectionHeaderData.fromMap({'title': title, 'subtitle': subtitle});

  JsonMap get title => _json['title'] as JsonMap;
  JsonMap? get subtitle => _json['subtitle'] as JsonMap?;
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
        required dataContext,
      }) {
        final sectionHeaderData = _SectionHeaderData.fromMap(
          data as Map<String, Object?>,
        );

        final titleNotifier = dataContext.subscribeToString(
          sectionHeaderData.title,
        );
        final subtitleNotifier = dataContext.subscribeToString(
          sectionHeaderData.subtitle,
        );

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: titleNotifier,
                builder: (context, title, _) => Text(
                  title ?? '',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: subtitleNotifier,
                builder: (context, subtitle, _) {
                  if (subtitle == null) return const SizedBox.shrink();
                  return Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  );
                },
              ),
            ],
          ),
        );
      },
);
