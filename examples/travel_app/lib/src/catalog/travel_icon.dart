import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

enum TravelIcons {
  // Location
  location,
  hotel,
  restaurant,
  airport,
  train,
  car,

  // Time
  date,
  time,
  calendar,

  // People
  people,
  person,
  family,

  // Finance
  creditCard,
  wallet,
  receipt,

  // Activities
  hiking,
  swimming,
  surfing,
  skiing,
  museum,
}

final travelIcon = CatalogItem(
  name: 'travelIcon',
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
  dataSchema: Schema.object(
    properties: {
      'icon': Schema.enumString(
        enumValues: TravelIcons.values.map((e) => e.name).toList(),
        description:
            'The name of the travel icon to display. *only* the given '
            'values can be used!',
      ),
    },
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
