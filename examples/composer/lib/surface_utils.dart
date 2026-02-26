// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:genui/genui.dart';

import 'sample_parser.dart';

const kProtocolVersion = 'v0.9';

/// Merges a list of component maps by their `id` field.
/// Later entries override earlier ones with the same ID.
Map<String, Map<String, dynamic>> mergeComponentsById(
  List<dynamic> components, [
  Map<String, Map<String, dynamic>>? existing,
]) {
  final map = existing ?? <String, Map<String, dynamic>>{};
  for (final comp in components) {
    if (comp is Map<String, dynamic> && comp['id'] != null) {
      map[comp['id'] as String] = comp;
    }
  }
  return map;
}

/// Sets a value at a nested path in a data model map.
/// Path format: "/segment1/segment2/..." — leading slashes are stripped.
void setNestedValue(
  Map<String, dynamic> model,
  String path,
  Object value,
) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return;

  Map<String, dynamic> current = model;
  for (int i = 0; i < segments.length - 1; i++) {
    current.putIfAbsent(segments[i], () => <String, dynamic>{});
    final next = current[segments[i]];
    if (next is Map<String, dynamic>) {
      current = next;
    } else {
      return; // Path conflict, skip
    }
  }

  current.putIfAbsent(segments.last, () => value);
}

/// Detects the root component ID from a list of component maps.
///
/// The root is the component whose ID is not referenced as a child by any
/// other component. Falls back to `'root'` if detection is ambiguous.
String detectRootId(List<dynamic> components) {
  final allIds = components
      .whereType<Map<String, dynamic>>()
      .map((c) => c['id'] as String?)
      .whereType<String>()
      .toSet();

  final referencedIds = <String>{};
  for (final comp in components) {
    if (comp is Map<String, dynamic>) {
      _collectStringValues(comp, allIds, referencedIds);
    }
  }

  final rootCandidates = allIds.difference(referencedIds);
  return rootCandidates.isNotEmpty ? rootCandidates.first : 'root';
}

/// Recursively walks [obj] and adds any string values that appear in
/// [knownIds] to [result]. Skips the component's own 'id' key.
void _collectStringValues(
  Object? obj,
  Set<String> knownIds,
  Set<String> result, {
  String? parentKey,
}) {
  if (obj is Map<String, dynamic>) {
    for (final entry in obj.entries) {
      _collectStringValues(
        entry.value,
        knownIds,
        result,
        parentKey: entry.key,
      );
    }
  } else if (obj is List) {
    for (final item in obj) {
      _collectStringValues(item, knownIds, result);
    }
  } else if (obj is String && parentKey != 'id' && knownIds.contains(obj)) {
    result.add(obj);
  }
}

/// Reconstructs full A2UI JSONL from a components array and optional data
/// model. Each message is pretty-printed and separated by a blank line.
String componentsToJsonl(
  String componentsJson, {
  String? dataJson,
  String surfaceId = 'editor',
}) {
  final encoder = const JsonEncoder.withIndent('  ');
  final messages = <String>[];

  // 1. createSurface
  messages.add(encoder.convert({
    'version': kProtocolVersion,
    'createSurface': {
      'surfaceId': surfaceId,
      'catalogId': basicCatalogId,
      'sendDataModel': true,
    },
  }));

  // 2. updateComponents
  try {
    final parsed = jsonDecode(componentsJson.trim());
    if (parsed is List) {
      final rootId = detectRootId(parsed);
      messages.add(encoder.convert({
        'version': kProtocolVersion,
        'updateComponents': {
          'surfaceId': surfaceId,
          'root': rootId,
          'components': parsed,
        },
      }));
    }
  } catch (_) {
    // If components can't be parsed, skip the updateComponents message.
  }

  // 3. updateDataModel (optional)
  if (dataJson != null && dataJson.trim().isNotEmpty) {
    try {
      final parsed = jsonDecode(dataJson.trim());
      if (parsed is Map<String, dynamic> && parsed.isNotEmpty) {
        messages.add(encoder.convert({
          'version': kProtocolVersion,
          'updateDataModel': {
            'surfaceId': surfaceId,
            'path': '/',
            'value': parsed,
          },
        }));
      }
    } catch (_) {}
  }

  return messages.join('\n\n');
}

/// Creates a [SurfaceController], feeds the parsed sample messages into it,
/// and returns the controller along with the discovered surface IDs.
Future<({SurfaceController controller, List<String> surfaceIds})>
    loadSampleSurface(String rawContent) async {
  final catalog = BasicCatalogItems.asCatalog();
  final controller = SurfaceController(catalogs: [catalog]);
  final surfaceIds = <String>[];

  final sub = controller.surfaceUpdates.listen((update) {
    if (update is SurfaceAdded) {
      surfaceIds.add(update.surfaceId);
    }
  });

  try {
    final sample = SampleParser.parseString(rawContent);
    await sample.messages.listen(controller.handleMessage).asFuture<void>();
  } catch (_) {
    // Caller can check surfaceIds.isEmpty to detect failure.
  }

  await sub.cancel();

  return (controller: controller, surfaceIds: surfaceIds);
}
