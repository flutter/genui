// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  JsonMap toAiInput() {
    return {'listings': listings.map((e) => e.toAiInput()).toList()};
  }
}

abstract class Listing {
  String get listingSelectionId;
}

class HotelListing implements Listing {
  final String name;
  final String location;
  final double pricePerNight;
  final List<String> images;
  final HotelSearch search;

  @override
  final String listingSelectionId;

  HotelListing({
    required this.name,
    required this.location,
    required this.pricePerNight,
    required this.listingSelectionId,
    required this.images,
    required this.search,
  });

  late final String description =
      '$name in $location, \$${pricePerNight.ceil()}';

  static HotelListing fromJson(JsonMap json) {
    return HotelListing(
      name: json['name'] as String,
      location: json['location'] as String,
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      images: List<String>.from(json['images'] as List),
      listingSelectionId: json['listingSelectionId'] as String,
      search: HotelSearch.fromJson(json['search'] as JsonMap),
    );
  }

  JsonMap toJson() {
    return {
      'name': name,
      'location': location,
      'pricePerNight': pricePerNight,
      'images': images,
      'listingSelectionId': listingSelectionId,
      'search': search.toJson(),
    };
  }

  JsonMap toAiInput() {
    return {
      'description': description,
      'images': images,
      'listingSelectionId': listingSelectionId,
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
