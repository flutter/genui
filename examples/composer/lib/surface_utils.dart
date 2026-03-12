// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'sample_parser.dart';

final _logger = Logger('SurfaceUtils');

const kProtocolVersion = 'v0.9';

Map<String, Map<String, Object?>> mergeComponentsById(
  List<Object?> components, [
  Map<String, Map<String, Object?>>? existing,
]) {
  final map = existing ?? <String, Map<String, Object?>>{};
  for (final comp in components) {
    if (comp is Map<String, Object?> && comp['id'] != null) {
      map[comp['id'] as String] = comp;
    }
  }
  return map;
}

/// Sets a value at a nested path in a data model map.
/// Path format: "/segment1/segment2/..." — leading slashes are stripped.
void setNestedValue(Map<String, Object?> model, String path, Object value) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return;

  Map<String, Object?> current = model;
  for (int i = 0; i < segments.length - 1; i++) {
    current.putIfAbsent(segments[i], () => <String, Object?>{});
    final next = current[segments[i]];
    if (next is Map<String, Object?>) {
      current = next;
    } else {
      return; // Path conflict, skip.
    }
  }

  current[segments.last] = value;
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

  messages.add(
    encoder.convert({
      'version': kProtocolVersion,
      'createSurface': {
        'surfaceId': surfaceId,
        'catalogId': basicCatalogId,
        'sendDataModel': true,
      },
    }),
  );

  try {
    final parsed = jsonDecode(componentsJson.trim());
    if (parsed is List) {
      messages.add(
        encoder.convert({
          'version': kProtocolVersion,
          'updateComponents': {
            'surfaceId': surfaceId,
            'root': 'root',
            'components': parsed,
          },
        }),
      );
    }
  } catch (e) {
    _logger.fine('Could not parse components JSON, skipping', e);
  }

  if (dataJson != null && dataJson.trim().isNotEmpty) {
    try {
      final parsed = jsonDecode(dataJson.trim());
      if (parsed is Map<String, Object?> && parsed.isNotEmpty) {
        messages.add(
          encoder.convert({
            'version': kProtocolVersion,
            'updateDataModel': {
              'surfaceId': surfaceId,
              'path': '/',
              'value': parsed,
            },
          }),
        );
      }
    } catch (e) {
      _logger.fine('Could not parse data model JSON, skipping', e);
    }
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
  } catch (e, s) {
    _logger.warning('Error loading sample surface', e, s);
  }

  await sub.cancel();

  return (controller: controller, surfaceIds: surfaceIds);
}
