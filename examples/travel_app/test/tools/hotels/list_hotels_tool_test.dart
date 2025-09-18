// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/tools/booking/list_hotels_tool.dart';
import 'package:travel_app/src/tools/booking/model.dart';

final _hotelSearch = HotelSearch(
  query: 'hotels in New York',
  checkIn: DateTime.parse('2025-10-01T00:00:00.000'),
  checkOut: DateTime.parse('2025-10-05T00:00:00.000'),
  guests: 2,
);

void main() {
  group('ListHotelsTool', () {
    group('HotelListing', () {
      test('fromJson and toJson', () {
        final json = {
          'name': 'The Grand Hotel',
          'location': 'New York, NY',
          'pricePerNight': 299.99,
          'images': ['image1.jpg', 'image2.jpg'],
          'listingSelectionId': 'a-random-id',
          'search': _hotelSearch.toJson(),
        };

        final listing = HotelListing.fromJson(json);

        expect(listing.name, 'The Grand Hotel');
        expect(listing.location, 'New York, NY');
        expect(listing.pricePerNight, 299.99);
        expect(listing.images, ['image1.jpg', 'image2.jpg']);
        expect(listing.listingSelectionId, isNotEmpty);

        expect(
          listing.toJson(),
          json..['listingSelectionId'] = listing.listingSelectionId,
        );
      });
    });

    group('HotelSearchResult', () {
      test('fromJson and toJson', () {
        final json = <String, Object?>{
          'listings': [
            {
              'name': 'The Grand Hotel',
              'location': 'New York, NY',
              'pricePerNight': 299.99,
              'images': ['image1.jpg', 'image2.jpg'],
              'listingSelectionId': 'a-random-id',
              'search': _hotelSearch.toJson(),
            },
          ],
        };

        final searchResult = HotelSearchResult.fromJson(json);

        expect(searchResult.listings.length, 1);
        expect(searchResult.listings.first.name, 'The Grand Hotel');
        expect(searchResult.listings.first.listingSelectionId, isNotEmpty);

        expect(
          searchResult.toJson(),
          json..['listings'] = [searchResult.listings.first.toJson()],
        );
      });
    });

    group('HotelSearch', () {
      test('fromJson and toJson', () {
        final checkIn = DateTime(2025, 10, 01);
        final checkOut = DateTime(2025, 10, 05);

        final json = {
          'query': 'hotels in New York',
          'checkIn': checkIn.toIso8601String(),
          'checkOut': checkOut.toIso8601String(),
          'guests': 2,
        };

        final search = HotelSearch.fromJson(json);

        expect(search.query, 'hotels in New York');
        expect(search.checkIn, checkIn);
        expect(search.checkOut, checkOut);
        expect(search.guests, 2);

        expect(search.toJson(), json);
      });
    });

    group('ListHotelsTool', () {
      test('invoke calls onListHotels and returns correct JSON', () async {
        final tool = ListHotelsTool(
          onListHotels: (search) async {
            expect(search.query, 'hotels in New York');
            expect(search.checkIn, DateTime.parse('2025-10-01T00:00:00.000'));
            expect(search.checkOut, DateTime.parse('2025-10-05T00:00:00.000'));
            expect(search.guests, 2);
            return HotelSearchResult(
              listings: [
                HotelListing(
                  name: 'The Grand Hotel',
                  location: 'New York, NY',
                  pricePerNight: 299.99,
                  images: ['image1.jpg', 'image2.jpg'],
                  listingSelectionId: 'a-random-id',
                  search: _hotelSearch,
                ),
              ],
            );
          },
        );

        final args = {
          'query': 'hotels in New York',
          'checkIn': '2025-10-01',
          'checkOut': '2025-10-05',
          'guests': 2,
        };

        final result = await tool.invoke(args);
        final listings = result['listings'] as List<dynamic>;
        final listing = listings.first as Map<String, dynamic>;
        expect(listing['listingSelectionId'], isNotEmpty);
      });
    });
  });
}
