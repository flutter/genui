// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum TravelIcon {
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
  wallet,
  receipt,
}

IconData iconFor(TravelIcon icon) {
  switch (icon) {
    case TravelIcon.location:
      return Icons.location_on;
    case TravelIcon.hotel:
      return Icons.hotel;
    case TravelIcon.restaurant:
      return Icons.restaurant;
    case TravelIcon.airport:
      return Icons.airplanemode_active;
    case TravelIcon.train:
      return Icons.train;
    case TravelIcon.car:
      return Icons.directions_car;
    case TravelIcon.date:
      return Icons.date_range;
    case TravelIcon.time:
      return Icons.access_time;
    case TravelIcon.calendar:
      return Icons.calendar_today;
    case TravelIcon.people:
      return Icons.people;
    case TravelIcon.person:
      return Icons.person;
    case TravelIcon.family:
      return Icons.family_restroom;
    case TravelIcon.wallet:
      return Icons.account_balance_wallet;
    case TravelIcon.receipt:
      return Icons.receipt;
  }
}
