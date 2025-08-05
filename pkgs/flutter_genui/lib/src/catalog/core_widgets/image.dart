import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../../model/catalog_item.dart';

final _schema = Schema.object(
  properties: {
    'url': Schema.string(description: 'The URL of the image to display.'),
    'assetName': Schema.string(
      description: 'The name of the asset to display.',
    ),
    'fit': Schema.enumString(
      description: 'How the image should be inscribed into the box.',
      enumValues: BoxFit.values.map((e) => e.name).toList(),
    ),
  },
  optionalProperties: ['url', 'assetName', 'fit'],
);

extension type _ImageData.fromMap(Map<String, Object?> _json) {
  factory _ImageData({String? url, String? assetName, String? fit}) =>
      _ImageData.fromMap({'url': url, 'assetName': assetName, 'fit': fit});

  String? get url => _json['url'] as String?;
  String? get assetName => _json['assetName'] as String?;
  BoxFit? get fit => _json['fit'] != null
      ? BoxFit.values.firstWhere((e) => e.name == _json['fit'] as String)
      : null;
}

final image = CatalogItem(
  name: 'image',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final imageData = _ImageData.fromMap(data as Map<String, Object?>);

        final url = imageData.url;
        final assetName = imageData.assetName;

        if (url != null && assetName != null) {
          throw Exception(
            'Image widget must have either a url or an assetName, but not '
            'both.',
          );
        }

        if (url == null && assetName == null) {
          throw Exception(
            'Image widget must have either a url or an assetName.',
          );
        }

        if (url != null) {
          return Image.network(url, fit: imageData.fit);
        }

        if (assetName != null) {
          return Image.asset(assetName, fit: imageData.fit);
        }

        return const SizedBox();
      },
);
