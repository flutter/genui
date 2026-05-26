// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:meta/meta.dart' show internal;

import 'data_model.dart';
import 'ui_models.dart';

/// A callback to get a component definition by its ID.
typedef GetComponentCallback = Component? Function(String componentId);

/// A callback that builds a child widget for a catalog item.
typedef ChildBuilderCallback =
    Widget Function(String id, [DataContext? dataContext]);

/// A callback that builds an example of a catalog item.
///
/// The returned string must be a valid JSON representation of a list of
/// component objects. One of the components in the list must have the `id`
/// 'root'.
typedef ExampleBuilderCallback = String Function();

/// A callback that builds a widget for a catalog item.
typedef CatalogWidgetBuilder = Widget Function(CatalogItemContext itemContext);

/// Context provided to a [CatalogItem]'s widget builder.
///
/// Internally backed by the substrate's [core.ComponentContext], plus
/// Flutter-specific extras (build context, dispatch callbacks, error
/// reporting). The public GenUI authoring API remains the shim getters and
/// callbacks on this class: [id], [type], [data], [surfaceId],
/// [getComponent], [dataContext], [buildChild], and related callbacks.
final class CatalogItemContext {
  /// Creates a [CatalogItemContext] from the legacy public GenUI fields.
  ///
  /// Internally this builds a small core [core.ComponentContext] so widget
  /// authoring stays source-compatible while the renderer substrate is core.
  CatalogItemContext({
    required String id,
    required String type,
    required Map<String, Object?> data,
    required this.buildChild,
    required this.dispatchEvent,
    required this.buildContext,
    required this.dataContext,
    required GetComponentCallback getComponent,
    required this.getCatalogItem,
    required String surfaceId,
    required this.reportError,
  }) : _componentContext = _standaloneContext(
         id: id,
         type: type,
         data: data,
         surfaceId: surfaceId,
       ),
       _getComponentOverride = getComponent;

  /// Creates a [CatalogItemContext] from a substrate [core.ComponentContext].
  ///
  /// This constructor is for GenUI renderer internals only. Catalog authors
  /// should receive instances from the renderer; tests that need to construct
  /// one manually can use the public constructor or
  /// [CatalogItemContext.forTesting].
  @internal
  CatalogItemContext.fromCore({
    required core.ComponentContext componentContext,
    required this.buildChild,
    required this.dispatchEvent,
    required this.buildContext,
    required this.dataContext,
    required this.getCatalogItem,
    required this.reportError,
  }) : _componentContext = componentContext,
       _getComponentOverride = null;

  /// Test-only convenience constructor that builds a stand-alone
  /// [core.SurfaceModel] + [core.ComponentContext] from raw fields, avoiding
  /// the need for tests to wire up a full surface.
  @visibleForTesting
  factory CatalogItemContext.forTesting({
    required String id,
    required String type,
    required Map<String, Object?> data,
    required ChildBuilderCallback buildChild,
    required DispatchEventCallback dispatchEvent,
    required BuildContext buildContext,
    required DataContext dataContext,
    required CatalogItem? Function(String type) getCatalogItem,
    required String surfaceId,
    required void Function(Object error, StackTrace? stack) reportError,
  }) {
    return CatalogItemContext(
      id: id,
      type: type,
      data: data,
      buildChild: buildChild,
      dispatchEvent: dispatchEvent,
      buildContext: buildContext,
      dataContext: dataContext,
      getComponent: (_) => null,
      getCatalogItem: getCatalogItem,
      surfaceId: surfaceId,
      reportError: reportError,
    );
  }

  /// The wrapped substrate context. Source of truth for component identity,
  /// raw properties, and access to other components on the surface.
  final core.ComponentContext _componentContext;

  final GetComponentCallback? _getComponentOverride;

  /// Callback to build a child widget by its component ID.
  final ChildBuilderCallback buildChild;

  /// Callback to dispatch UI events (e.g., button taps) back to the system.
  final DispatchEventCallback dispatchEvent;

  /// The Flutter [BuildContext] for this widget.
  final BuildContext buildContext;

  /// The Flutter-side [DataContext] for accessing the data model, dispatching
  /// catalog functions, and subscribing to dynamic-value streams.
  final DataContext dataContext;

  /// Callback to retrieve a catalog item definition by its type name.
  final CatalogItem? Function(String type) getCatalogItem;

  /// Callback to report an error that occurred within this component.
  final void Function(Object error, StackTrace? stack) reportError;

  CatalogItemContext._copy({
    required core.ComponentContext componentContext,
    required GetComponentCallback? getComponentOverride,
    required this.buildChild,
    required this.dispatchEvent,
    required this.buildContext,
    required this.dataContext,
    required this.getCatalogItem,
    required this.reportError,
  }) : _componentContext = componentContext,
       _getComponentOverride = getComponentOverride;

  /// Returns a copy of this context with selected Flutter-side callbacks
  /// replaced while preserving the same private substrate context.
  @internal
  CatalogItemContext withOverrides({
    ChildBuilderCallback? buildChild,
    DispatchEventCallback? dispatchEvent,
    BuildContext? buildContext,
    DataContext? dataContext,
    CatalogItem? Function(String type)? getCatalogItem,
    void Function(Object error, StackTrace? stack)? reportError,
  }) {
    return CatalogItemContext._copy(
      componentContext: _componentContext,
      getComponentOverride: _getComponentOverride,
      buildChild: buildChild ?? this.buildChild,
      dispatchEvent: dispatchEvent ?? this.dispatchEvent,
      buildContext: buildContext ?? this.buildContext,
      dataContext: dataContext ?? this.dataContext,
      getCatalogItem: getCatalogItem ?? this.getCatalogItem,
      reportError: reportError ?? this.reportError,
    );
  }

  /// The parsed data for this component from the AI-generated definition.
  Object get data => _componentContext.componentModel.properties;

  /// The unique identifier for this component instance.
  String get id => _componentContext.componentModel.id;

  /// The type of this component.
  String get type => _componentContext.componentModel.type;

  /// The ID of the surface this component belongs to.
  String get surfaceId => _componentContext.surface.id;

  /// Retrieves a component on the surface by its ID, or `null` if absent.
  Component? getComponent(String componentId) {
    final Component? override = _getComponentOverride?.call(componentId);
    if (override != null) return override;
    final core.ComponentModel? component = _componentContext
        .surface
        .componentsModel
        .get(componentId);
    return component == null ? null : Component.fromCore(component);
  }

  static core.ComponentContext _standaloneContext({
    required String id,
    required String type,
    required Map<String, Object?> data,
    required String surfaceId,
  }) {
    final surface = core.SurfaceModel<core.ComponentApi>(
      surfaceId,
      catalog: core.Catalog<core.ComponentApi>(
        id: 'catalog',
        components: const [],
      ),
    );
    final component = core.ComponentModel(id, type, data);
    surface.componentsModel.addComponent(component);
    return core.ComponentContext(surface, component);
  }
}

/// Defines a UI layout type, its schema, and how to build its widget.
@immutable
final class CatalogItem {
  /// Creates a new [CatalogItem].
  const CatalogItem({
    required this.name,
    required Schema dataSchema,
    required this.widgetBuilder,
    this.exampleData = const [],
    this.isImplicitlyFlexible = false,
  }) : _originalSchema = dataSchema;

  /// The widget type name used in JSON, e.g., 'TextChatMessage'.
  final String name;

  final Schema _originalSchema;

  /// The schema definition for this widget's data.
  ///
  /// It should contain all of the component specific properties, but not the
  /// `component` discriminator property, which will be automatically injected
  /// using the [name]. If the `component` property is already defined in the
  /// schema, it will be ignored.
  ObjectSchema get dataSchema {
    final Map<String, Object?> originalMap = _originalSchema.value;
    final Map<String, Object?> properties =
        originalMap['properties'] as Map<String, Object?>? ??
        <String, Object?>{};
    final List<Object?> requiredProps =
        originalMap['required'] as List<Object?>? ?? <Object?>[];

    return ObjectSchema.fromMap(<String, Object?>{
      ...originalMap,
      'properties': <String, Object?>{
        ...properties,
        'component': <String, Object?>{
          'type': 'string',
          'enum': <String>[name],
        },
      },
      'required': <Object?>['component', ...requiredProps],
    });
  }

  /// The builder for this widget.
  final CatalogWidgetBuilder widgetBuilder;

  /// Whether this component should be implicitly flexible when placed in a flex
  /// container (like Row/Column).
  ///
  /// If true, a [Row] or [Column] will automatically assign a flex weight to
  /// this component if one is not explicitly provided, wrapping it in a
  /// [Flexible] widget.
  /// This is useful for components that require bounded constraints, like
  /// [TextField] or [ListView].
  final bool isImplicitlyFlexible;

  /// A list of builder functions that each return a JSON string representing an
  /// example usage of this widget.
  ///
  /// Each returned string must be a valid JSON representation of a list of
  /// component objects. For the example to be renderable, one of the
  /// components in the list must have the `id` 'root', which will be used as
  /// the entry point for rendering.
  ///
  /// To catch real data returned by the AI for debugging or creating new
  /// examples, [configure logging](https://github.com/flutter/genui/blob/main/packages/genui/README.md#how-can-i-configure-logging)
  /// to `Level.ALL` and search for the string `"definition": {` in the logs.
  final List<ExampleBuilderCallback> exampleData;
}
