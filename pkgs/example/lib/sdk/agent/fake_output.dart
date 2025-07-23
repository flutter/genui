import 'package:example/sdk/catalog/carousel.dart';
import 'package:example/sdk/catalog/invitation.dart';
import 'package:example/sdk/catalog/text_intro.dart';

final invitationData = InvitationData(
  textIntroData: TextIntroData(
    h1: 'Hello, Ryan,',
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
      imageUrl: 'assets/explore/beach_bliss.png',
    ),
    CarouselItemData(
      title: 'Urban Escapes',
      imageUrl: 'assets/explore/urban_escapes.png',
    ),
    CarouselItemData(
      title: "Nature's Wonders",
      imageUrl: 'assets/explore/natures_wonder.png',
    ),
  ],
  chatHintText: 'Ask me anything',
);
