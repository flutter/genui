// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

final _schema = S.object(
  properties: {
    'imageUri': S.string(
      description: 'The URI of the image to display at the top of the card.',
    ),
    'title': S.string(
      description: 'The title of the card.',
    ),
    'subtitle': S.string(
      description: 'The subtitle of the card.',
    ),
    'body': S.string(
      description: 'The body text of the card.',
    ),
  },
  required: ['title', 'body'],
);

extension type _InformationCardData.fromMap(Map<String, Object?> _json) {
  factory _InformationCardData({
    String? imageUri,
    required String title,
    String? subtitle,
    required String body,
  }) =>
      _InformationCardData.fromMap({
        if (imageUri != null) 'imageUri': imageUri,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'body': body,
      });

  String? get imageUri => _json['imageUri'] as String?;
  String get title => _json['title'] as String;
  String? get subtitle => _json['subtitle'] as String?;
  String get body => _json['body'] as String;
}

final informationCard = CatalogItem(
  name: 'InformationCard',
  dataSchema: _schema,
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
    required values,
  }) {
    final cardData =
        _InformationCardData.fromMap(data as Map<String, Object?>);
    return SizedBox(
      width: 400,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cardData.imageUri != null)
              Image.network(
                cardData.imageUri!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
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
                  Text(
                    cardData.body,
                    style: Theme.of(context).textTheme.bodyMedium,
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
