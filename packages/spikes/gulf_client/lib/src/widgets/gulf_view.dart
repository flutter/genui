// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../core/interpreter.dart';
import '../core/widget_registry.dart';
import '../models/component.dart';
import 'gulf_provider.dart';

/// The main entry point for rendering a UI from the GULF Streaming Protocol.
///
/// This widget takes an [GulfInterpreter] and a [WidgetRegistry] and
/// constructs the corresponding Flutter widget tree. It listens to the
/// interpreter and rebuilds the UI when the state changes.
class GulfView extends StatefulWidget {
  /// Creates a widget that renders a UI from an GULF stream.
  ///
  /// The [interpreter] processes the stream and the [registry] provides the
  /// widget builders. The [onEvent] callback is invoked when a widget
  /// triggers an event.
  const GulfView({
    super.key,
    required this.interpreter,
    required this.registry,
    this.onEvent,
  });

  /// The interpreter that processes the GULF stream.
  final GulfInterpreter interpreter;

  /// The registry mapping component types to builder functions.
  final WidgetRegistry registry;

  /// A callback function that is invoked when an event is triggered by a
  /// widget.
  final ValueChanged<Map<String, dynamic>>? onEvent;

  @override
  State<GulfView> createState() => _GulfViewState();
}

class _GulfViewState extends State<GulfView> {
  @override
  void initState() {
    super.initState();
    widget.interpreter.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(GulfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interpreter != oldWidget.interpreter) {
      oldWidget.interpreter.removeListener(_rebuild);
      widget.interpreter.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.interpreter.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.interpreter.isReadyToRender) {
      return const Center(child: CircularProgressIndicator());
    }
    return GulfProvider(
      onEvent: widget.onEvent,
      child: _LayoutEngine(
        interpreter: widget.interpreter,
        registry: widget.registry,
      ),
    );
  }
}

class _LayoutEngine extends StatelessWidget {
  const _LayoutEngine({required this.interpreter, required this.registry});

  final GulfInterpreter interpreter;
  final WidgetRegistry registry;

  @override
  Widget build(BuildContext context) {
    return _buildNode(context, interpreter.rootComponentId!);
  }

  Widget _buildNode(
    BuildContext context,
    String componentId, [
    Set<String> visited = const {},
  ]) {
    if (visited.contains(componentId)) {
      return const Text('Error: cyclical layout detected');
    }
    final newVisited = {...visited, componentId};

    final component = interpreter.getComponent(componentId);
    if (component == null) {
      return const Text('Error: component not found');
    }

    final properties = component.componentProperties;
    final builder = registry.getBuilder(properties.runtimeType.toString());
    if (builder == null) {
      return Text(
        'Error: unknown component type ${properties.runtimeType.toString()}',
      );
    }

    // This is a bit of a hack to get the children of a component.
    // We should probably have a more generic way of doing this.
    final children = <String, List<Widget>>{};
    if (properties is RowProperties ||
        properties is ColumnProperties ||
        properties is ListProperties) {
      final childrenProp = (properties as dynamic).children as Children;
      if (childrenProp.explicitList != null) {
        children['children'] = childrenProp.explicitList!
            .map((id) => _buildNode(context, id, newVisited))
            .toList();
      } else if (childrenProp.template != null) {
        return _buildNodeWithTemplate(context, component, newVisited);
      }
    } else if (properties is CardProperties) {
      children['child'] = [_buildNode(context, properties.child, newVisited)];
    }

    final resolvedProperties = <String, Object?>{};
    // TODO(gspencer): find a more generic way to do this.
    if (properties is TextProperties) {
      resolvedProperties['text'] = _resolveValue(properties.text, null);
    } else if (properties is HeadingProperties) {
      resolvedProperties['text'] = _resolveValue(properties.text, null);
      resolvedProperties['level'] = properties.level;
    } else if (properties is ImageProperties) {
      resolvedProperties['url'] = _resolveValue(properties.url, null);
    } else if (properties is VideoProperties) {
      resolvedProperties['url'] = _resolveValue(properties.url, null);
    } else if (properties is AudioPlayerProperties) {
      resolvedProperties['url'] = _resolveValue(properties.url, null);
      resolvedProperties['description'] = _resolveValue(
        properties.description,
        null,
      );
    } else if (properties is ButtonProperties) {
      resolvedProperties['label'] = _resolveValue(properties.label, null);
      resolvedProperties['action'] = properties.action;
    } else if (properties is CheckBoxProperties) {
      resolvedProperties['label'] = _resolveValue(properties.label, null);
      resolvedProperties['value'] = _resolveValue(properties.value, null);
    } else if (properties is TextFieldProperties) {
      resolvedProperties['text'] = _resolveValue(properties.text, null);
      resolvedProperties['label'] = _resolveValue(properties.label, null);
      resolvedProperties['type'] = properties.type;
      resolvedProperties['validationRegexp'] = properties.validationRegexp;
    } else if (properties is DateTimeInputProperties) {
      resolvedProperties['value'] = _resolveValue(properties.value, null);
      resolvedProperties['enableDate'] = properties.enableDate;
      resolvedProperties['enableTime'] = properties.enableTime;
      resolvedProperties['outputFormat'] = properties.outputFormat;
    } else if (properties is MultipleChoiceProperties) {
      resolvedProperties['selections'] = _resolveValue(
        properties.selections,
        null,
      );
      resolvedProperties['options'] = properties.options;
      resolvedProperties['maxAllowedSelections'] =
          properties.maxAllowedSelections;
    } else if (properties is SliderProperties) {
      resolvedProperties['value'] = _resolveValue(properties.value, null);
      resolvedProperties['minValue'] = properties.minValue;
      resolvedProperties['maxValue'] = properties.maxValue;
    }

    return builder(context, component, resolvedProperties, children);
  }

  Widget _buildNodeWithTemplate(
    BuildContext context,
    Component component,
    Set<String> visited,
  ) {
    final properties = component.componentProperties as dynamic;
    final template = properties.children.template as Template;
    final data = interpreter.resolveDataBinding(template.dataBinding);
    if (data is! List) {
      return const SizedBox.shrink();
    }

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    final templateComponent = interpreter.getComponent(template.componentId);
    if (templateComponent == null) {
      return const Text('Error: template component not found');
    }
    final builder = registry.getBuilder(properties.runtimeType.toString());
    if (builder == null) {
      return Text(
        'Error: unknown component type ${properties.runtimeType.toString()}',
      );
    }
    final children = data.map((itemData) {
      final resolvedProperties = <String, Object?>{};
      final itemChildren = <String, List<Widget>>{};
      final itemBuilder = registry.getBuilder(
        templateComponent.componentProperties.runtimeType.toString(),
      );
      if (itemBuilder == null) {
        return Text(
          'Error: unknown component type ${templateComponent.componentProperties.runtimeType.toString()}',
        );
      }
      return itemBuilder(
        context,
        templateComponent,
        resolvedProperties,
        itemChildren,
      );
    }).toList();
    return builder(context, component, {}, {'children': children});
  }

  Object? _resolveValue(BoundValue? value, Map<String, dynamic>? itemData) {
    if (value == null) {
      return null;
    }
    if (value.literalString != null) {
      return value.literalString;
    } else if (value.literalNumber != null) {
      return value.literalNumber;
    } else if (value.literalBoolean != null) {
      return value.literalBoolean;
    } else if (value.path != null) {
      if (itemData != null) {
        return itemData[value.path!.substring(1)];
      } else {
        return interpreter.resolveDataBinding(value.path!);
      }
    }
    return null;
  }
}
