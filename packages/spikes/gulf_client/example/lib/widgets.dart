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
      style = Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
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
  registry.register('VideoProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Icon(Icons.videocam),
    );
  });
  registry.register('AudioPlayerProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Icon(Icons.audiotrack),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: children['child']?.first,
      ),
    );
  });
  registry.register('TabsProperties', (
    context,
    component,
    properties,
    children,
  ) {
    // This is a simplified version of Tabs. A real implementation would
    // need a TabController.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children['children'] ?? [],
    );
  });
  registry.register('DividerProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return const Divider();
  });
  registry.register('ModalProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return ElevatedButton(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: children['contentChild']?.first,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
      child: children['entryPointChild']?.first,
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
  registry.register('CheckBoxProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return CheckboxListTile(
      title: Text(properties['label'] as String? ?? ''),
      value: properties['value'] as bool? ?? false,
      onChanged: (value) {},
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
  registry.register('DateTimeInputProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return ElevatedButton(
      onPressed: () {
        showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
      },
      child: const Text('Select Date'),
    );
  });
  registry.register('MultipleChoiceProperties', (
    context,
    component,
    properties,
    children,
  ) {
    final options = properties['options'] as List<Option>? ?? [];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        return CheckboxListTile(
          title: Text(option.label.literalString ?? ''),
          value: false,
          onChanged: (value) {},
        );
      }).toList(),
    );
  });
  registry.register('SliderProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return Slider(
      value: properties['value'] as double? ?? 0.0,
      onChanged: (value) {},
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
