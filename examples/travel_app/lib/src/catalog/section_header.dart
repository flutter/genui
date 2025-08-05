// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = Schema.object(
  description: 'A widget to break up sections of a longer list of content.',
  properties: {
    'title': Schema.string(description: 'The title of the section.'),
    'subtitle': Schema.string(description: 'The subtitle of the section.'),
  },
);

extension type _SectionHeaderData.fromMap(Map<String, Object?> _json) {
  factory _SectionHeaderData({required String title, String? subtitle}) =>
      _SectionHeaderData.fromMap({'title': title, 'subtitle': subtitle});

  String get title => _json['title'] as String;
  String? get subtitle => _json['subtitle'] as String?;
}

final sectionHeaderCatalogItem = CatalogItem(
  name: 'sectionHeader',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
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
