// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:genui/genui.dart';

import 'sample_parser.dart';

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
