// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../core/interpreter.dart';
import '../core/widget_registry.dart';
import '../models/component.dart';
import 'component_properties_visitor.dart';
import 'gulf_provider.dart';

final _log = Logger('GulfView');

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
    if (widget.interpreter.error != null) {
      return Center(child: Text('Error: ${widget.interpreter.error}'));
    }
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
    _log.finer('Building node for componentId: $componentId');
    if (visited.contains(componentId)) {
      _log.severe('Cyclical layout detected for componentId: $componentId');
      return const Text('Error: cyclical layout detected');
    }
    final newVisited = {...visited, componentId};

    final component = interpreter.getComponent(componentId);
    if (component == null) {
      _log.severe('Component not found for id: $componentId');
      return const Text('Error: component not found');
    }

    final properties = component.componentProperties;
    final builder = registry.getBuilder(properties.runtimeType.toString());
    if (builder == null) {
      _log.severe(
        'Builder not found for component type: ${properties.runtimeType}',
      );
      return Text(
        'Error building node: Unknown component type: '
        '${properties.runtimeType}',
      );
    }

    final children = <String, List<Widget>>{};
    if (properties is HasChildren) {
      final childrenProp = (properties as HasChildren).children;
      if (childrenProp.explicitList != null) {
        children['children'] = childrenProp.explicitList!
            .map((id) => _buildNode(context, id, newVisited))
            .toList();
      } else if (childrenProp.template != null) {
        return _buildNodeWithTemplate(context, component, newVisited);
      }
    } else if (properties is CardProperties) {
      children['child'] = [_buildNode(context, properties.child, newVisited)];
    } else if (properties is TabsProperties) {
      children['children'] = properties.tabItems
          .map((item) => _buildNode(context, item.child, newVisited))
          .toList();
    } else if (properties is ModalProperties) {
      children['entryPointChild'] = [
        _buildNode(context, properties.entryPointChild, newVisited),
      ];
      children['contentChild'] = [
        _buildNode(context, properties.contentChild, newVisited),
      ];
    }

    final visitor = ComponentPropertiesVisitor(interpreter);
    final resolvedProperties = visitor.visit(properties, null);

    return builder(context, component, resolvedProperties, children);
  }

  Widget _buildNodeWithTemplate(
    BuildContext context,
    Component component,
    Set<String> visited,
  ) {
    _log.finer('Building node with template for component: ${component.id}');
    final properties = component.componentProperties as HasChildren;
    final template = properties.children.template!;
    _log.finer(
      'Template componentId: ${template.componentId}, '
      'dataBinding: ${template.dataBinding}',
    );
    final data = interpreter.resolveDataBinding(template.dataBinding);
    if (data is! List) {
      _log.warning(
        'Template data binding "${template.dataBinding}" did not resolve to a '
        'List. Resolved to: $data',
      );
      return const SizedBox.shrink();
    }

    if (data.isEmpty) {
      _log.info(
        'Template data for "${template.dataBinding}" is an empty list. '
        'Rendering nothing.',
      );
      return const SizedBox.shrink();
    }
    _log.finer('Template data has ${data.length} items.');
    final templateComponent = interpreter.getComponent(template.componentId);
    if (templateComponent == null) {
      _log.severe('Template component not found: ${template.componentId}');
      return const Text('Error: template component not found');
    }
    final builder = registry.getBuilder(properties.runtimeType.toString());
    if (builder == null) {
      return Text(
        'Error: unknown component type '
        '${properties.runtimeType}',
      );
    }
    final children = data.map((Object? itemData) {
      _log.finest('Building template item with data: $itemData');
      final visitor = ComponentPropertiesVisitor(interpreter);
      final resolvedProperties = visitor.visit(
        templateComponent.componentProperties,
        itemData as Map<String, Object?>,
      );
      final itemChildren = <String, List<Widget>>{};
      final itemBuilder = registry.getBuilder(
        templateComponent.componentProperties.runtimeType.toString(),
      );
      if (itemBuilder == null) {
        return Text(
          'Error building template: Unknown component type: '
          '${templateComponent.componentProperties.runtimeType}',
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
}
