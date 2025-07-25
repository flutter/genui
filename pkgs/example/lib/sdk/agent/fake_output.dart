import 'package:example/sdk/catalog/carousel.dart';
import 'package:example/sdk/catalog/invitation.dart';
import 'package:example/sdk/catalog/text_intro.dart';

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
