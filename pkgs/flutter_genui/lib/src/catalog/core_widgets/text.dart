// ignore_for_file: avoid_dynamic_calls

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import '../../model/catalog_item.dart';

final text = CatalogItem(
  name: 'text',
  dataSchema: Schema.object(
    properties: {'text': Schema.string(description: 'The text to display.')},
  ),
  widgetBuilder: ({
    required data,
    required id,
    required buildChild,
    required dispatchEvent,
    required context,
  }) {
    return Text(
      data['text'] as String,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  },
);
