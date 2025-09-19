// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Action;
import 'package:gulf_client/gulf_client.dart';

void registerGulfWidgets(WidgetRegistry registry) {
  registry.register('ColumnProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: getMainAxisAlignment(
        properties['distribution'] as String?,
      ),
      crossAxisAlignment: getCrossAxisAlignment(
        properties['alignment'] as String?,
      ),
      children: children['children'] ?? [],
    );
  });
  registry.register('RowProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return Row(
      mainAxisAlignment: getMainAxisAlignment(
        properties['distribution'] as String?,
      ),
      crossAxisAlignment: getCrossAxisAlignment(
        properties['alignment'] as String?,
      ),
      children: children['children'] ?? [],
    );
  });
  registry.register('TextProperties', (
    context,
    component,
    properties,
    children,
  ) {
    final text = properties['text'] as String? ?? '';
    TextStyle? style;
    if (component.id.contains('name')) {
      style = Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold);
    } else if (component.id.contains('detail')) {
      style = Theme.of(context).textTheme.bodyMedium;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Text(text, style: style),
    );
  });
  registry.register('HeadingProperties', (
    context,
    component,
    properties,
    children,
  ) {
    final text = properties['text'] as String? ?? '';
    final level = (component.componentProperties as HeadingProperties).level;
    TextStyle? style;
    style = switch (level) {
      '1' => Theme.of(context).textTheme.headlineSmall,
      '2' => Theme.of(context).textTheme.titleLarge,
      '3' => Theme.of(context).textTheme.titleMedium,
      '4' => Theme.of(context).textTheme.bodyLarge,
      '5' => Theme.of(context).textTheme.bodyMedium,
      '6' => Theme.of(context).textTheme.bodySmall,
      _ => Theme.of(context).textTheme.bodyMedium,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: Text(text, style: style),
    );
  });
  registry.register('ImageProperties', (
    context,
    component,
    properties,
    children,
  ) {
    final url = properties['url'] as String?;
    if (url == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.broken_image),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.network(url, width: 64, height: 64),
    );
  });
  registry.register('CardProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: children['child']?.first,
      ),
    );
  });
  registry.register('ButtonProperties', (
    context,
    component,
    properties,
    children,
  ) {
    final action = properties['action'] as Action;
    return ElevatedButton(
      onPressed: () {
        GulfProvider.of(context)?.onEvent?.call({'action': action.action});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event: ${action.action}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Text(properties['label'] as String? ?? ''),
    );
  });
  registry.register('TextFieldProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          decoration: InputDecoration(hintText: properties['label'] as String?),
        ),
      ),
    );
  });
  registry.register('ListProperties', (
    context,
    component,
    properties,
    children,
  ) {
    final direction = properties['direction'] as String?;
    if (direction == 'horizontal') {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children['children'] ?? []),
      );
    }
    // Default to vertical.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children['children'] ?? [],
    );
  });
}

MainAxisAlignment getMainAxisAlignment(String? alignment) {
  switch (alignment) {
    case 'start':
      return MainAxisAlignment.start;
    case 'end':
      return MainAxisAlignment.end;
    case 'center':
      return MainAxisAlignment.center;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start;
  }
}

CrossAxisAlignment getCrossAxisAlignment(String? alignment) {
  switch (alignment) {
    case 'start':
      return CrossAxisAlignment.start;
    case 'end':
      return CrossAxisAlignment.end;
    case 'center':
      return CrossAxisAlignment.center;
    case 'stretch':
      return CrossAxisAlignment.stretch;
    default:
      return CrossAxisAlignment.center;
  }
}
