// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'model.dart';

/// A mock hotel service to simulate hotel listings.
class HotelService {
  static HotelService instance = HotelService._();

  HotelService._();

  final Map<String, HotelListing> listings = {};
  final _random = Random();

  String _generateListingId() => _random.nextInt(1000000000).toString();

  HotelListing _rememberListing(HotelListing listing) {
    listings[listing.listingId] = listing;
    return listing;
  }

  Future<HotelSearchResult> listHotels(HotelSearch search) async {
    // Mock implementation
    return HotelSearchResult(
      listings: [
        _rememberListing(
          HotelListing(
            name: 'The Grand Flutter Hotel',
            location: 'Mountain View, CA',
            pricePerNight: 250.0,
            listingId: _generateListingId(),
            images: ['assets/travel_images/brooklyn_bridge_new_york.jpg'],
            search: search,
          ),
        ),
        _rememberListing(
          HotelListing(
            name: 'The Dart Inn',
            location: 'Sunnyvale, CA',
            pricePerNight: 150.0,
            listingId: _generateListingId(),
            images: ['assets/travel_images/eiffel_tower_construction_1888.jpg'],
            search: search,
          ),
        ),
      ],
    );
  }
}
