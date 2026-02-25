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

IconData iconFor(TravelIcon icon) => switch (icon) {
  .location => Icons.location_on,
  .hotel => Icons.hotel,
  .restaurant => Icons.restaurant,
  .airport => Icons.airplanemode_active,
  .train => Icons.train,
  .car => Icons.directions_car,
  .date => Icons.date_range,
  .time => Icons.access_time,
  .calendar => Icons.calendar_today,
  .people => Icons.people,
  .person => Icons.person,
  .family => Icons.family_restroom,
  .wallet => Icons.account_balance_wallet,
  .receipt => Icons.receipt,
};
