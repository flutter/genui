// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../utils.dart';

final _schema = S.object(
  properties: {
    'imageChildId': S.string(
      description:
          'The ID of the Image widget to display at the top of the '
          'card. The Image fit should typically be "cover". Be sure to create '
          'an Image widget with a matching ID.',
    ),
    'title': S.string(description: 'The title of the card.'),
    'subtitle': S.string(description: 'The subtitle of the card.'),
    'body': S.string(
      description: 'The body text of the card. This supports markdown.',
    ),
  },
  required: ['title', 'body'],
);

extension type _InformationCardData.fromMap(Map<String, Object?> _json) {
  factory _InformationCardData({
    String? imageChildId,
    required String title,
    String? subtitle,
    required String body,
  }) => _InformationCardData.fromMap({
    if (imageChildId != null) 'imageChildId': imageChildId,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'body': body,
  });

  String? get imageChildId => _json['imageChildId'] as String?;
  String get title => _json['title'] as String;
  String? get subtitle => _json['subtitle'] as String?;
  String get body => _json['body'] as String;
}

final informationCard = CatalogItem(
  name: 'InformationCard',
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
        final cardData = _InformationCardData.fromMap(
          data as Map<String, Object?>,
        );
        final imageChild = cardData.imageChildId != null
            ? buildChild(cardData.imageChildId!)
            : null;
        return Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageChild != null)
                  SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: imageChild,
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardData.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (cardData.subtitle != null)
                        Text(
                          cardData.subtitle!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      const SizedBox(height: 8.0),
                      MarkdownBody(
                        data: cardData.body,
                        styleSheet: getMarkdownStyleSheet(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
);
