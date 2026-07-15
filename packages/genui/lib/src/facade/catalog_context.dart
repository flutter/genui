// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:genai_primitives/genai_primitives.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../model/catalog.dart';
import '../model/catalog_item.dart';
import '../primitives/simple_items.dart';

/// A compact summary of a single catalog item.
///
/// Used in a [CatalogManifest] to give the model a lightweight index of the
/// available components without inlining their full schemas.
final class CatalogManifestItem {
  /// Creates a [CatalogManifestItem].
  const CatalogManifestItem({required this.name, required this.description});

  /// The catalog item name, e.g. `Card`.
  final String name;

  /// A short, human-readable description of the component.
  ///
  /// Derived from the component's schema description.
  final String description;

  /// Returns a JSON-serializable representation.
  JsonMap toJson() => {'name': name, 'description': description};
}

/// A compact index of a catalog, suitable for an initial system prompt.
///
/// The manifest contains only [CatalogManifestItem] descriptions. Full schemas
/// and examples are loaded on demand through [CatalogContext.loadItems].
final class CatalogManifest {
  /// Creates a [CatalogManifest].
  const CatalogManifest({required this.catalogId, required this.items});

  /// The id of the catalog this manifest describes, if any.
  final String? catalogId;

  /// The compact descriptions for every item in the catalog.
  final List<CatalogManifestItem> items;

  /// Returns a JSON-serializable representation.
  JsonMap toJson() => {
    if (catalogId != null) 'catalogId': catalogId,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

/// The full, model-facing detail for a single catalog item.
///
/// Returned inside a [LoadCatalogItemsResult] when the model asks to load a
/// component. This is the on-demand "body" for a component: the complete
/// [schema] and [examples]. The [schema] is the full component-envelope
/// schema (including `id` and `component`, plus per-property descriptions)
/// for use inside `updateComponents.components`.
final class CatalogItemDetails {
  /// Creates a [CatalogItemDetails].
  const CatalogItemDetails({
    required this.name,
    required this.description,
    required this.schema,
    required this.examples,
  });

  /// The catalog item name, e.g. `Card`.
  final String name;

  /// A short, human-readable description of the component.
  final String description;

  /// The complete component-envelope JSON schema, including `id` and
  /// `component`.
  final JsonMap schema;

  /// Example component payloads decoded from the item's JSON examples.
  final List<Object?> examples;

  /// Returns a JSON-serializable representation.
  JsonMap toJson() => {
    'name': name,
    'description': description,
    'schema': schema,
    'examples': examples,
  };
}

/// The result of a [CatalogContext.loadItems] call.
///
/// Wraps the loaded item [items] with the [catalogId] they were loaded from.
/// The set of loaded names is `items.map((e) => e.name)`; unknown names cause
/// the call to throw rather than producing a partial result.
final class LoadCatalogItemsResult {
  /// Creates a [LoadCatalogItemsResult].
  const LoadCatalogItemsResult({required this.catalogId, required this.items});

  /// The id of the catalog the items were loaded from, if any.
  final String? catalogId;

  /// The loaded item details, in request order (de-duplicated).
  final List<CatalogItemDetails> items;

  /// Returns a JSON-serializable representation.
  JsonMap toJson() => {
    if (catalogId != null) 'catalogId': catalogId,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

/// Resolves catalog context for incremental catalog prompt mode.
///
/// Pure functions over the in-process [Catalog]; testable without any LLM
/// provider. Integrations register [loadCatalogItemsTool] with their tool
/// framework and forward calls to [loadItems].
abstract final class CatalogContext {
  CatalogContext._();

  /// The canonical `loadCatalogItems` tool definition for incremental mode.
  ///
  /// Register this tool's `name`, `description` and `inputSchema` with the
  /// LLM provider's tool framework, and forward the parsed input to
  /// [loadItems]. The prompt builder names the same tool, so registering this
  /// definition keeps the prompt and the registered tool in sync.
  static final ToolDefinition<Map<String, Object?>> loadCatalogItemsTool =
      ToolDefinition(
        name: 'loadCatalogItems',
        description:
            'Loads the A2UI schemas and examples for the named catalog items. '
            'Pass all the components you need for this turn in one call, using '
            'exact item names from the catalog manifest. Returns each '
            'component\'s schema and examples so you can emit valid '
            'updateComponents.',
        inputSchema: S.object(
          properties: {
            'items': S.list(
              items: S.string(
                description: 'A catalog item name from the manifest.',
              ),
              description:
                  'The catalog item names to load: all the components '
                  'you need for this turn.',
            ),
          },
          required: ['items'],
        ),
      );

  /// Builds a compact manifest of [catalog].
  ///
  /// The manifest contains only names and descriptions; it never includes full
  /// schemas or examples.
  static CatalogManifest manifest(Catalog catalog) {
    return CatalogManifest(
      catalogId: catalog.catalogId,
      items: [
        for (final item in catalog.items)
          CatalogManifestItem(
            name: item.name,
            description: _descriptionFor(item),
          ),
      ],
    );
  }

  /// Loads exact details for the requested item [names] from [catalog].
  ///
  /// Behavior:
  /// - Unknown item name: throws [CatalogItemNotFoundException].
  /// - Duplicate names: returned once, preserving first-seen order.
  /// - Empty request: returns an empty [LoadCatalogItemsResult.items] list.
  static LoadCatalogItemsResult loadItems(
    Catalog catalog,
    Iterable<String> names,
  ) {
    final Map<String, CatalogItem> byName = {
      for (final item in catalog.items) item.name: item,
    };

    final seen = <String>{};
    final details = <CatalogItemDetails>[];
    for (final name in names) {
      if (!seen.add(name)) continue;
      final CatalogItem? item = byName[name];
      if (item == null) {
        throw CatalogItemNotFoundException(name, catalogId: catalog.catalogId);
      }
      details.add(
        CatalogItemDetails(
          name: item.name,
          description: _descriptionFor(item),
          schema: _componentEnvelopeSchema(item),
          examples: _examplesFor(item),
        ),
      );
    }

    return LoadCatalogItemsResult(catalogId: catalog.catalogId, items: details);
  }

  /// Resolves a compact description from the item's schema description, falling
  /// back to a generic label when the schema has none.
  static String _descriptionFor(CatalogItem item) {
    final Map<String, Object?> value = item.dataSchema.value;
    final Object? description = value['description'];
    if (description is String && description.trim().isNotEmpty) {
      return description.trim();
    }
    return 'A2UI component named ${item.name}.';
  }

  /// Builds the full component-envelope schema for [item].
  ///
  /// [CatalogItem.dataSchema] already injects the `component` discriminator and
  /// marks it required, but does not include `id`. This adds `id` to both
  /// `properties` and `required` so the schema describes the complete object
  /// expected inside `updateComponents.components`.
  static JsonMap _componentEnvelopeSchema(CatalogItem item) {
    final itemSchema = Map<String, Object?>.from(item.dataSchema.value);

    final itemProperties = Map<String, Object?>.from(
      itemSchema['properties'] as Map<String, Object?>? ?? const {},
    )..remove('id');

    final itemRequired = List<Object?>.from(
      itemSchema['required'] as List<Object?>? ?? const [],
    );

    return {
      ...itemSchema,
      'properties': {
        ...itemProperties,
        'id': {
          'type': 'string',
          'description':
              'Unique component id. Use "root" for the root component.',
        },
      },
      'required': ['id', ...itemRequired.where((value) => value != 'id')],
    };
  }

  /// Decodes each of the item's example builders as structured JSON.
  static List<Object?> _examplesFor(CatalogItem item) {
    return [
      for (final buildExample in item.exampleData) jsonDecode(buildExample()),
    ];
  }
}
