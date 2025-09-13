// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import '../tools/booking/booking_service.dart';
import '../tools/booking/model.dart';

final _schema = S.object(
  description: 'A widget to check out set of listings.',
  properties: {
    'listingIds': S.list(description: 'Items to checkout.', items: S.string()),
  },
  required: ['listingIds'],
);

extension type _ListingsBookerData.fromMap(Map<String, Object?> _json) {
  factory _ListingsBookerData({required List<String> listingIds}) =>
      _ListingsBookerData.fromMap({'listingIds': listingIds});

  List<String> get listingIds => (_json['listingIds'] as List).cast<String>();
}

final listingsBooker = CatalogItem(
  name: 'ListingsBooker',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final listingsBookerData = _ListingsBookerData.fromMap(
          data as Map<String, Object?>,
        );
        return _ListingsBooker(listingIds: listingsBookerData.listingIds);
      },
  exampleData: [
    () {
      final start1 = DateTime.now().add(const Duration(days: 5));
      final end1 = start1.add(const Duration(days: 2));
      final start2 = end1.add(const Duration(days: 1));
      final end2 = start2.add(const Duration(days: 2));

      final listingId1 = BookingService.instance
          .listHotelsSync(
            HotelSearch(query: '', checkIn: start1, checkOut: end1, guests: 1),
          )
          .listings
          .first
          .listingId;
      final listingId2 = BookingService.instance
          .listHotelsSync(
            HotelSearch(query: '', checkIn: start2, checkOut: end2, guests: 1),
          )
          .listings
          .last
          .listingId;

      return {
        'root': 'book_listings',
        'widgets': [
          {
            'id': 'book_listings',
            'widget': {
              'BookListings': {
                'listingIds': [listingId1, listingId2],
                'itineraryName': 'Dart and Flutter deep dive.',
              },
            },
          },
        ],
      };
    },
  ],
);

class _ListingsBooker extends StatelessWidget {
  final List<String> listingIds;

  const _ListingsBooker({required this.listingIds});

  @override
  Widget build(BuildContext context) {
    final listings = listingIds
        .map((id) => BookingService.instance.listings[id])
        .where((listing) => listing != null)
        .cast<HotelListing>()
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: listing.images.isNotEmpty
                ? Image.asset(
                    listing.images.first,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : const SizedBox(width: 80, height: 80),
            title: Text(listing.name),
            subtitle: Text(listing.location),
            trailing: Text('\$${listing.pricePerNight.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }
}
