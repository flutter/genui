// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../utils.dart';

final _schema = S.object(
  properties: {
    'component': S.string(enumValues: ['InformationCard']),
    'imageChildId': S.string(
      description:
          'The ID of the Image widget to display at the top of the '
          'card. The Image fit should typically be "cover". Be sure to create '
          'an Image widget with a matching ID.',
    ),
    'title': A2uiSchemas.stringReference(description: 'The title of the card.'),
    'subtitle': A2uiSchemas.stringReference(
      description: 'The subtitle of the card.',
    ),
    'body': A2uiSchemas.stringReference(
      description: 'The body text of the card. This supports markdown.',
    ),
  },
  required: ['component', 'title', 'body'],
);

extension type _InformationCardData.fromMap(Map<String, Object?> _json) {
  factory _InformationCardData({
    String? imageChildId,
    required JsonMap title,
    JsonMap? subtitle,
    required JsonMap body,
  }) => _InformationCardData.fromMap({
    'imageChildId': ?imageChildId,
    'title': title,
    'subtitle': ?subtitle,
    'body': body,
  });

  String? get imageChildId => _json['imageChildId'] as String?;
  Object get title => _json['title'] as Object;
  Object? get subtitle => _json['subtitle'];
  Object get body => _json['body'] as Object;
}

final informationCard = CatalogItem(
  name: 'InformationCard',
  dataSchema: _schema,
  exampleData: [
    () => '''
      [
        {
          "id": "root",
          "component": "InformationCard",
          "title": "Beautiful Scenery",
          "subtitle": "A stunning view",
          "body": "This is a beautiful place to visit in the summer.",
          "imageChildId": "image1"
        },
        {
          "id": "image1",
          "component": "Image",
          "url": "assets/travel_images/canyonlands_national_park_utah.jpg"
        }
      ]
    ''',
  ],
  widgetBuilder: (context) {
    final cardData = _InformationCardData.fromMap(
      context.data as Map<String, Object?>,
    );
    final Widget? imageChild = cardData.imageChildId != null
        ? context.buildChild(cardData.imageChildId!)
        : null;

    return _InformationCard(
      imageChild: imageChild,
      title: cardData.title,
      subtitle: cardData.subtitle,
      body: cardData.body,
      dataContext: context.dataContext,
    );
  },
);

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    this.imageChild,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.dataContext,
  });

  final Widget? imageChild;
  final Object title;
  final Object? subtitle;
  final Object body;
  final DataContext dataContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageChild != null)
              SizedBox(width: double.infinity, height: 200, child: imageChild),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoundString(
                    dataContext: dataContext,
                    value: title,
                    builder: (context, title) => Text(
                      title ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (subtitle != null)
                    BoundString(
                      dataContext: dataContext,
                      value: subtitle!,
                      builder: (context, subtitle) {
                        if (subtitle == null) return const SizedBox.shrink();
                        return Text(
                          subtitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        );
                      },
                    ),
                  const SizedBox(height: 8.0),
                  BoundString(
                    dataContext: dataContext,
                    value: body,
                    builder: (context, body) =>
                        MarkdownWidget(text: body ?? ''),
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
