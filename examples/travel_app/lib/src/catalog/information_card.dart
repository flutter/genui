// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../utils.dart';

final _schema = S.object(
  properties: {
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
  required: ['title', 'body'],
);

extension type _InformationCardData.fromMap(Map<String, Object?> _json) {
  factory _InformationCardData({
    String? imageChildId,
    required JsonMap title,
    JsonMap? subtitle,
    required JsonMap body,
  }) => _InformationCardData.fromMap({
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
  widgetBuilder:
      ({
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
        final imageChild = cardData.imageChildId != null
            ? buildChild(cardData.imageChildId!)
            : null;

        final titleNotifier = dataContext.subscribeToString(cardData.title);
        final subtitleNotifier = dataContext.subscribeToString(
          cardData.subtitle,
        );
        final bodyNotifier = dataContext.subscribeToString(cardData.body);

        return _InformationCard(
          imageChild: imageChild,
          titleNotifier: titleNotifier,
          subtitleNotifier: subtitleNotifier,
          bodyNotifier: bodyNotifier,
        );
      },
);

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    this.imageChild,
    required this.titleNotifier,
    required this.subtitleNotifier,
    required this.bodyNotifier,
  });

  final Widget? imageChild;
  final ValueNotifier<String?> titleNotifier;
  final ValueNotifier<String?> subtitleNotifier;
  final ValueNotifier<String?> bodyNotifier;

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
                  ValueListenableBuilder<String?>(
                    valueListenable: titleNotifier,
                    builder: (context, title, _) => Text(
                      title ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: subtitleNotifier,
                    builder: (context, subtitle, _) {
                      if (subtitle == null) return const SizedBox.shrink();
                      return Text(
                        subtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      );
                    },
                  ),
                  const SizedBox(height: 8.0),
                  ValueListenableBuilder<String?>(
                    valueListenable: bodyNotifier,
                    builder: (context, body, _) =>
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
