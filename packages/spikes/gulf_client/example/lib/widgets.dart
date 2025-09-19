// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Action;
import 'package:gulf_client/gulf_client.dart';
import 'package:logging/logging.dart';

final _log = Logger('gulf.example.widgets');

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
        _log.info(
          'Button ${component.id} pressed. Firing event: ${action.action}',
        );
        final interpreter = GulfProvider.of(context)!.interpreter;
        final visitor = ComponentPropertiesVisitor(interpreter);
        final resolvedContext = <String, dynamic>{};
        if (action.context != null) {
          for (final item in action.context!) {
            resolvedContext[item.key] = visitor.resolveValue(item.value, null);
          }
        }
        GulfProvider.of(context)?.onEvent?.call({
          'action': action.action,
          'sourceComponentId': component.id,
          'context': resolvedContext,
        });
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
    return _Checkbox(properties: properties, component: component);
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
    return _MultipleChoice(properties: properties, component: component);
  });
  registry.register('SliderProperties', (
    context,
    component,
    properties,
    children,
  ) {
    return _Slider(properties: properties, component: component);
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

class _Checkbox extends StatefulWidget {
  const _Checkbox({required this.properties, required this.component});
  final Map<String, Object?> properties;
  final Component component;

  @override
  State<_Checkbox> createState() => _CheckboxState();
}

class _CheckboxState extends State<_Checkbox> {
  bool? _value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _value = widget.properties['value'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final properties = widget.properties;
    final path =
        (widget.component.componentProperties as CheckBoxProperties).value.path;
    return CheckboxListTile(
      title: Text(properties['label'] as String? ?? ''),
      value: _value,
      onChanged: (value) {
        _log.info(
          'Checkbox ${widget.component.id} changed to $value. '
          'Updating path: $path',
        );
        setState(() {
          _value = value;
        });
        if (path != null) {
          GulfProvider.of(context)?.onDataModelUpdate?.call(path, value);
        }
        GulfProvider.of(context)?.onEvent?.call({
          'action': 'checkbox_change',
          'sourceComponentId': widget.component.id,
          'context': {'value': value},
        });
      },
    );
  }
}

class _MultipleChoice extends StatefulWidget {
  const _MultipleChoice({required this.properties, required this.component});
  final Map<String, Object?> properties;
  final Component component;

  @override
  State<_MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<_MultipleChoice> {
  List<String> _selectedValues = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final selections = widget.properties['selections'] is List
        ? widget.properties['selections'] as List<dynamic>? ?? []
        : null;
    _selectedValues = selections?.map((e) => e.toString()).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final properties = widget.properties;
    final options = properties['options'] as List<Option>? ?? [];
    final path =
        (widget.component.componentProperties as MultipleChoiceProperties)
            .selections
            .path;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isSelected = _selectedValues.contains(option.value);
        return CheckboxListTile(
          title: Text(option.label.literalString ?? ''),
          value: isSelected,
          onChanged: (value) {
            _log.info(
              'MultipleChoice ${widget.component.id} option ${option.value} '
              'changed to $value.',
            );
            setState(() {
              if (value == true) {
                _selectedValues.add(option.value);
              } else {
                _selectedValues.remove(option.value);
              }
            });
            if (path != null) {
              _log.info(
                'Updating path $path with new values: $_selectedValues',
              );
              GulfProvider.of(
                context,
              )?.onDataModelUpdate?.call(path, _selectedValues);
            }
            GulfProvider.of(context)?.onEvent?.call({
              'action': 'multiple_choice_change',
              'sourceComponentId': widget.component.id,
              'context': {'selections': _selectedValues},
            });
          },
        );
      }).toList(),
    );
  }
}

class _Slider extends StatefulWidget {
  const _Slider({required this.properties, required this.component});
  final Map<String, Object?> properties;
  final Component component;

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  double? _value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _value = widget.properties['value'] as double? ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final properties = widget.properties;
    final path =
        (widget.component.componentProperties as SliderProperties).value.path;
    return Slider(
      value: _value!,
      min: properties['minValue'] as double? ?? 0.0,
      max: properties['maxValue'] as double? ?? 100.0,
      onChanged: (value) {
        setState(() {
          _value = value;
        });
      },
      onChangeEnd: (value) {
        _log.info(
          'Slider ${widget.component.id} changed to $value. '
          'Updating path: $path',
        );
        if (path != null) {
          GulfProvider.of(context)?.onDataModelUpdate?.call(path, value);
        }
        GulfProvider.of(context)?.onEvent?.call({
          'action': 'slider_change',
          'sourceComponentId': widget.component.id,
          'context': {'value': value},
        });
      },
    );
  }
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
