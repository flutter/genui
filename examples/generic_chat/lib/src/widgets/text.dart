import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import '../catalog_item.dart';

final text = CatalogItem(
  name: 'text',
  dataSchema: Schema.object(
    properties: {
      'text': Schema.string(
        description: 'The text to display.',
      ),
    },
  ),
  widgetBuilder: (data, id, buildChild, dispatchEvent, context) {
    return Text(
      data['text'] as String,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  },
);
