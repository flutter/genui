// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

/// A semantic vocabulary of icons relevant to a travel application.
enum TravelIcons {
  location,
  hotel,
  restaurant,
  airport,
  train,
  car,
  date,
  time,
  calendar,
  people,
  person,
  family,
  creditCard,
  wallet,
  receipt,
  hiking,
  swimming,
  surfing,
  skiing,
  museum,
}

/// A catalog item for a widget that maps a semantic, travel-related name to a
/// specific Material Design [IconData].
///
/// This provides the AI with a constrained, domain-specific vocabulary of icons
/// (e.g., 'hotel', 'hiking', 'airport') rather than requiring it to know the
/// names of the entire Material Icons library. This ensures that the icons used
/// are always relevant to the travel context and maintain a consistent visual
/// style throughout the application.
final travelIcon = CatalogItem(
  name: 'TravelIcon',
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
      }) {
        final props = data as Map<String, Object?>;
        try {
          final icon = TravelIcons.values.byName(props['icon'] as String);
          return Icon(_mapIcon(icon));
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
  dataSchema: S.object(
    properties: {
      'icon': S.string(
        enumValues: TravelIcons.values.map((e) => e.name).toList(),
        description:
            'The name of the travel icon to display. *only* the given '
            'values can be used!',
      ),
    },
    required: ['icon'],
  ),
);

IconData _mapIcon(TravelIcons icon) {
  switch (icon) {
    case TravelIcons.location:
      return Icons.location_on;
    case TravelIcons.hotel:
      return Icons.hotel;
    case TravelIcons.restaurant:
      return Icons.restaurant;
    case TravelIcons.airport:
      return Icons.flight;
    case TravelIcons.train:
      return Icons.train;
    case TravelIcons.car:
      return Icons.directions_car;
    case TravelIcons.date:
      return Icons.date_range;
    case TravelIcons.time:
      return Icons.access_time;
    case TravelIcons.calendar:
      return Icons.calendar_today;
    case TravelIcons.people:
      return Icons.people;
    case TravelIcons.person:
      return Icons.person;
    case TravelIcons.family:
      return Icons.family_restroom;
    case TravelIcons.creditCard:
      return Icons.credit_card;
    case TravelIcons.wallet:
      return Icons.account_balance_wallet;
    case TravelIcons.receipt:
      return Icons.receipt;
    case TravelIcons.hiking:
      return Icons.hiking;
    case TravelIcons.swimming:
      return Icons.pool;
    case TravelIcons.surfing:
      return Icons.surfing;
    case TravelIcons.skiing:
      return Icons.downhill_skiing;
    case TravelIcons.museum:
      return Icons.museum;
  }
}
