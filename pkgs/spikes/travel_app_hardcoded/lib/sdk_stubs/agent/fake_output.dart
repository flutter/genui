// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../catalog/elements/carousel.dart';
import '../catalog/elements/filter.dart';
import '../catalog/elements/text_intro.dart';
import '../catalog/messages/elicitation.dart';
import '../catalog/messages/invitation.dart';
import '../catalog/messages/result.dart';

final fakeInvitationData = InvitationData(
  textIntroData: TextIntroData(
    h1: 'Hello Ryan,',
    h2: 'Welcome to traveling with Compass',
    intro:
        'Explore our promotions below or let me know '
        'what you are looking for and I will generate '
        'a custom itinerary just for you.',
  ),
  exploreTitle: 'Explore',
  exploreItems: [
    CarouselItemData(
      title: 'Beach Bliss',
      assetUrl: 'assets/explore/beach_bliss.png',
    ),
    CarouselItemData(
      title: 'Urban Escapes',
      assetUrl: 'assets/explore/urban_escapes.png',
    ),
    CarouselItemData(
      title: "Nature's Wonders",
      assetUrl: 'assets/explore/natures_wonders.png',
    ),
  ],
  chatHintText: 'Ask me anything',
);

final fakeElicitationData = ElicitationData(
  textIntroData: TextIntroData(
    intro: 'OK I can help generate itinerary as follows or tap to edit',
  ),
  filterData: FilterData([
    FilterItemData(label: 'Zermatt', icon: Icons.location_pin),
    FilterItemData(label: '3 days', icon: Icons.calendar_month),
    FilterItemData(
      label: '2 adults + 1 child',
      icon: Icons.supervised_user_circle_outlined,
    ),
    FilterItemData(label: 'Low cost', icon: Icons.money),
    FilterItemData(label: 'Medium activity', icon: Icons.run_circle_sharp),
  ], submitLabel: 'Generate'),
);

final fakeResultData = ResultData(
  textIntroData: TextIntroData(
    h2: 'Zermatt adventure',
    intro: '3 days - 3 people',
  ),
  imageAssetUrl: 'assets/result.png',
  linkUrl: 'https://www.zermatt.ch/en',
);
