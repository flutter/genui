// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'model.dart';

class HotelService {
  static HotelService instance = HotelService._();

  HotelService._();

  final Map<String, HotelListing> _listings = {};

  HotelListing _rememberListing(HotelListing listing) {
    _listings[listing.listingId] = listing;
    return listing;
  }

  Future<HotelSearchResult> onListHotels(HotelSearch search) async {
    // Mock implementation
    return HotelSearchResult(
      listings: [
        _rememberListing(
          HotelListing(
            name: 'The Grand Flutter Hotel',
            location: 'Mountain View, CA',
            pricePerNight: 250.0,
            listingId: '1',
            images: ['assets/travel_images/brooklyn_bridge_new_york.jpg'],
            search: search,
          ),
        ),
        _rememberListing(
          HotelListing(
            name: 'The Dart Inn',
            location: 'Sunnyvale, CA',
            pricePerNight: 150.0,
            listingId: '2',
            images: ['assets/travel_images/eiffel_tower_construction_1888.jpg'],
            search: search,
          ),
        ),
      ],
    );
  }
}
