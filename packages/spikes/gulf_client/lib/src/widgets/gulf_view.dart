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

    if (component.children?.template != null) {
      return _buildNodeWithTemplate(context, component, newVisited);
    }

    final builder = registry.getBuilder(component.type);
    if (builder == null) {
      return Text('Error: unknown component type ${component.type}');
    }

    final properties = _resolveProperties(component, null);
    final children = <String, List<Widget>>{};
    if (component.child != null) {
      children['child'] = [_buildNode(context, component.child!, newVisited)];
    }
    if (component.children?.explicitList != null) {
      children['children'] = component.children!.explicitList!
          .map((id) => _buildNode(context, id, newVisited))
          .toList();
    }

    return builder(context, component, properties, children);
  }

  Widget _buildNodeWithTemplate(
    BuildContext context,
    Component component,
    Set<String> visited,
  ) {
    final template = component.children!.template!;
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
    final builder = registry.getBuilder(component.type);
    if (builder == null) {
      return Text('Error: unknown component type ${component.type}');
    }
    final children = data.map((itemData) {
      final properties = _resolveProperties(
        templateComponent,
        itemData as Map<String, dynamic>,
      );
      final itemChildren = <String, List<Widget>>{};
      final itemBuilder = registry.getBuilder(templateComponent.type);
      if (itemBuilder == null) {
        return Text('Error: unknown component type ${templateComponent.type}');
      }
      return itemBuilder(context, templateComponent, properties, itemChildren);
    }).toList();
    return builder(context, component, {}, {'children': children});
  }

  Object? _resolveValue(Value? value, Map<String, dynamic>? itemData) {
    if (value == null) {
      return null;
    }
    if (value.literalString != null) {
      return value.literalString;
    } else if (value.literalNumber != null) {
      return value.literalNumber;
    } else if (value.literalBoolean != null) {
      return value.literalBoolean;
    } else if (value.literalObject != null) {
      return value.literalObject;
    } else if (value.literalArray != null) {
      return value.literalArray;
    } else if (value.path != null) {
      if (itemData != null) {
        return itemData[value.path!.substring(1)];
      } else {
        return interpreter.resolveDataBinding(value.path!);
      }
    }
    return null;
  }

  Map<String, Object?> _resolveProperties(
    Component component,
    Map<String, dynamic>? itemData,
  ) {
    final properties = <String, Object?>{};
    final componentJson = component.toJson();

    for (final entry in componentJson.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        continue;
      }

      if (key == 'value') {
        properties['text'] = _resolveValue(
          Value.fromJson(value as Map<String, dynamic>),
          itemData,
        );
      } else {
        properties[key] = value;
      }
    }
    return properties;
  }
}
