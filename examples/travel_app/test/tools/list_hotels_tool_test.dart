// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/src/tools/list_hotels_tool.dart';

void main() {
  group('ListHotelsTool', () {
    group('HotelListing', () {
      test('fromJson and toJson', () {
        final json = {
          'name': 'The Grand Hotel',
          'location': 'New York, NY',
          'pricePerNight': 299.99,
          'images': ['image1.jpg', 'image2.jpg'],
          'listingId': '12345',
        };

        final listing = HotelListing.fromJson(json);

        expect(listing.name, 'The Grand Hotel');
        expect(listing.location, 'New York, NY');
        expect(listing.pricePerNight, 299.99);
        expect(listing.images, ['image1.jpg', 'image2.jpg']);
        expect(listing.listingId, '12345');

        expect(listing.toJson(), json);
      });
    });

    group('HotelSearchResult', () {
      test('fromJson and toJson', () {
        final json = {
          'listings': [
            {
              'name': 'The Grand Hotel',
              'location': 'New York, NY',
              'pricePerNight': 299.99,
              'images': ['image1.jpg', 'image2.jpg'],
              'listingId': '12345',
            },
          ],
        };

        final searchResult = HotelSearchResult.fromJson(json);

        expect(searchResult.listings.length, 1);
        expect(searchResult.listings.first.name, 'The Grand Hotel');

        expect(searchResult.toJson(), json);
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
        final searchResult = HotelSearchResult(
          listings: [
            HotelListing(
              name: 'The Grand Hotel',
              location: 'New York, NY',
              pricePerNight: 299.99,
              images: ['image1.jpg', 'image2.jpg'],
              listingId: '12345',
            ),
          ],
        );

        final tool = ListHotelsTool(
          onListHotels: (search) {
            expect(search.query, 'hotels in New York');
            expect(search.checkIn, DateTime.parse('2025-10-01T00:00:00.000'));
            expect(search.checkOut, DateTime.parse('2025-10-05T00:00:00.000'));
            expect(search.guests, 2);
            return searchResult;
          },
        );

        final args = {
          'query': 'hotels in New York',
          'checkIn': '2025-10-01',
          'checkOut': '2025-10-05',
          'guests': 2,
        };

        final result = await tool.invoke(args);

        expect(result, searchResult.toJson());
      });
    });
  });
}
