// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter_genui/flutter_genui.dart';

class HotelListing {
  final String name;
  final String location;
  final double pricePerNight;
  final List<String> images;
  final String listingId;

  HotelListing({
    required this.name,
    required this.location,
    required this.pricePerNight,
    required this.listingId,
    required this.images,
  });

  static HotelListing fromJson(JsonMap json) {
    return HotelListing(
      name: json['name'] as String,
      location: json['location'] as String,
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      images: List<String>.from(json['images'] as List),
      listingId: json['listingId'] as String,
    );
  }

  JsonMap toJson() {
    return {
      'name': name,
      'location': location,
      'pricePerNight': pricePerNight,
      'images': images,
      'listingId': listingId,
    };
  }
}

class HotelSearch {
  final String query;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  HotelSearch({
    required this.query,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  });

  static HotelSearch fromJson(JsonMap json) {
    return HotelSearch(
      query: json['query'] as String,
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      guests: json['guests'] as int,
    );
  }

  JsonMap toJson() {
    return {
      'query': query,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'guests': guests,
    };
  }
}

/// An [AiTool] for listing hotels.
class ListHotelsTool extends AiTool<Map<String, Object?>> {
  /// Creates a [ListHotelsTool].
  ListHotelsTool({
    required this.onListHotels,
    required Catalog catalog,
    required this.configuration,
  }) : super(
         name: 'listHotels',
         description: 'Lists hotels based on the provided criteria.',
         parameters: S.object(
           properties: {
             'action': S.string(
               description:
                   'The action to perform. You must choose from the available '
                   'actions. If you choose the `add` action, you must choose a '
                   'new unique surfaceId. If you choose the `update` action, '
                   'you must choose an existing surfaceId.',
               enumValues: [
                 if (configuration.actions.allowCreate) 'add',
                 if (configuration.actions.allowUpdate) 'update',
               ],
             ),
             'surfaceId': S.string(
               description:
                   'The unique identifier for the UI surface to create or '
                   'update. If you are adding a new surface this *must* be a '
                   'new, unique identified that has never been used for any '
                   'existing surfaces shown in the context.',
             ),
             'definition': S.object(
               properties: {
                 'root': S.string(
                   description:
                       'The ID of the root widget. This ID must correspond to '
                       'the ID of one of the widgets in the `widgets` list.',
                 ),
                 'widgets': S.list(
                   items: catalog.schema,
                   description: 'A list of widget definitions.',
                   minItems: 1,
                 ),
               },
               description:
                   'A schema for a simple UI tree to be rendered by '
                   'Flutter.',
               required: ['root', 'widgets'],
             ),
           },
           required: ['action', 'surfaceId', 'definition'],
         ),
       );

  /// The callback to invoke when listing hotels.
  final void Function(HotelSearch search) onListHotels;

  /// The configuration of the Gen UI system.
  final GenUiConfiguration configuration;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final surfaceId = args['surfaceId'] as String;
    final definition = args['definition'] as JsonMap;
    onAddOrUpdate(surfaceId, definition);
    return {'surfaceId': surfaceId, 'status': 'SUCCESS'};
  }
}
