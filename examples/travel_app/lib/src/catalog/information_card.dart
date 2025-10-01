// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:flutter_genui/src/model/gulf_schemas.dart';

import '../utils.dart';

final _schema = S.object(
  properties: {
    'imageChildId': S.string(
      description:
          'The ID of the Image widget to display at the top of the '
          'card. The Image fit should typically be "cover". Be sure to create '
          'an Image widget with a matching ID.',
    ),
    'title': GulfSchemas.stringReference,
    'subtitle': GulfSchemas.stringReference,
    'body': GulfSchemas.stringReference,
  },
  required: ['title', 'body'],
);

extension type _InformationCardData.fromMap(Map<String, Object?> _json) {
  factory _InformationCardData({
    String? imageChildId,
    required JsonMap title,
    JsonMap? subtitle,
    required JsonMap body,
  }) =>
      _InformationCardData.fromMap({
        if (imageChildId != null) 'imageChildId': imageChildId,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'body': body,
      });

  String? get imageChildId => _json['imageChildId'] as String?;
  JsonMap get title => _json['title'] as JsonMap;
  JsonMap? get subtitle => _json['subtitle'] as JsonMap?;
  JsonMap get body => _json['body'] as JsonMap;
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
    required dataContext,
  }) {
    final cardData = _InformationCardData.fromMap(
      data as Map<String, Object?>,
    );
    final imageChild =
        cardData.imageChildId != null ? buildChild(cardData.imageChildId!) : null;

    final titleRef = cardData.title;
    final titlePath = titleRef['path'] as String?;
    final titleLiteral = titleRef['literalString'] as String?;
    final titleNotifier = titlePath != null
        ? dataContext.subscribe<String>(titlePath)
        : ValueNotifier<String?>(titleLiteral);

    final subtitleRef = cardData.subtitle;
    final subtitlePath = subtitleRef?['path'] as String?;
    final subtitleLiteral = subtitleRef?['literalString'] as String?;
    final subtitleNotifier = subtitlePath != null
        ? dataContext.subscribe<String>(subtitlePath)
        : ValueNotifier<String?>(subtitleLiteral);

    final bodyRef = cardData.body;
    final bodyPath = bodyRef['path'] as String?;
    final bodyLiteral = bodyRef['literalString'] as String?;
    final bodyNotifier = bodyPath != null
        ? dataContext.subscribe<String>(bodyPath)
        : ValueNotifier<String?>(bodyLiteral);

    return ValueListenableBuilder<String?>(
      valueListenable: titleNotifier,
      builder: (context, title, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: subtitleNotifier,
          builder: (context, subtitle, child) {
            return ValueListenableBuilder<String?>(
              valueListenable: bodyNotifier,
              builder: (context, body, child) {
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
                                title ?? '',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              const SizedBox(height: 8.0),
                              MarkdownWidget(text: body ?? ''),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  },
);