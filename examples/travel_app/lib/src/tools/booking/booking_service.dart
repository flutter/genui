// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'model.dart';

/// A fake booking service to simulate hotel listings and bookings.
class BookingService {
  static BookingService instance = BookingService._();

  BookingService._();

  final Map<String, Listing> listings = {};

  final _random = Random();
  String _generateListingSelectionId() =>
      _random.nextInt(1000000000).toString();

  T _rememberListing<T extends Listing>(T listing) {
    listings[listing.listingSelectionId] = listing;
    return listing;
  }

  Future<HotelSearchResult> listHotels(HotelSearch search) async {
    // ignore: inference_failure_on_instance_creation
    await Future.delayed(const Duration(milliseconds: 100));
    return listHotelsSync(search);
  }

  Future<void> bookSelections(
    List<String> listingSelectionIds,
    String paymentMethodId,
  ) async {
    // ignore: inference_failure_on_instance_creation
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Synchronous version for example data generation.
  HotelSearchResult listHotelsSync(HotelSearch search) {
    // Mock implementation
    return HotelSearchResult(
      listings: [
        _rememberListing(
          HotelListing(
            name: 'The Dart Inn',
            location: 'Sunnyvale, CA',
            pricePerNight: 150.0,
            listingSelectionId: _generateListingSelectionId(),
            images: ['assets/booking_service/dart_inn.png'],
            search: search,
          ),
        ),
        _rememberListing(
          HotelListing(
            name: 'The Flutter Hotel',
            location: 'Mountain View, CA',
            pricePerNight: 250.0,
            listingSelectionId: _generateListingSelectionId(),
            images: ['assets/booking_service/flutter_hotel.png'],
            search: search,
          ),
        ),
      ],
    );
  }
}
