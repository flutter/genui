// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'model.dart';

/// An [AiTool] for listing hotels.
class ListHotelsTool extends AiTool<Map<String, Object?>> {
  /// Creates a [ListHotelsTool].
  ListHotelsTool({required this.onListHotels})
    : super(
        name: 'listHotels',
        description: 'Lists hotels based on the provided criteria.',
        parameters: S.object(
          properties: {
            'query': S.string(
              description: 'The search query, e.g., "hotels in Paris".',
            ),
            'checkIn': S.string(
              description: 'The check-in date in ISO 8601 format (YYYY-MM-DD).',
              format: 'date',
            ),
            'checkOut': S.string(
              description:
                  'The check-out date in ISO 8601 format (YYYY-MM-DD).',
              format: 'date',
            ),
            'guests': S.integer(
              description: 'The number of guests.',
              minimum: 1,
            ),
          },
          required: ['query', 'checkIn', 'checkOut', 'guests'],
        ),
      );

  /// The callback to invoke when searching hotels.
  final Future<HotelSearchResult> Function(HotelSearch search) onListHotels;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final search = HotelSearch.fromJson(args);
    return (await onListHotels(search)).toAiInput();
  }
}
