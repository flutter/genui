// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter_genui/flutter_genui.dart';

class HotelSearchResult {
  final List<HotelListing> listings;

  HotelSearchResult({required this.listings});

  static HotelSearchResult fromJson(JsonMap json) {
    return HotelSearchResult(
      listings: (json['listings'] as List)
          .map((e) => HotelListing.fromJson(e as JsonMap))
          .toList(),
    );
  }

  JsonMap toJson() {
    return {'listings': listings.map((e) => e.toJson()).toList()};
  }
}

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
  final HotelSearchResult Function(HotelSearch search) onListHotels;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final search = HotelSearch.fromJson(args);
    return onListHotels(search).toJson();
  }
}

HotelSearchResult onListHotels(HotelSearch search) {
  // Mock implementation
  return HotelSearchResult(
    listings: [
      HotelListing(
        name: 'The Grand Flutter Hotel',
        location: 'Mountain View, CA',
        pricePerNight: 250.0,
        listingId: '1',
        images: ['assets/travel_images/brooklyn_bridge_new_york.jpg'],
      ),
      HotelListing(
        name: 'The Dart Inn',
        location: 'Sunnyvale, CA',
        pricePerNight: 150.0,
        listingId: '2',
        images: ['assets/travel_images/eiffel_tower_construction_1888.jpg'],
      ),
    ],
  );
}
