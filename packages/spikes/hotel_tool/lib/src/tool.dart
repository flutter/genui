import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'simple_items.dart';

typedef SearchHotelCallback =
    Future<JsonMap> Function(
      String query,
      DateTime checkIn,
      DateTime checkOut,
      int guests,
    );

typedef BookHotelCallback =
    Future<JsonMap> Function(
      String propertyToken,
      DateTime checkIn,
      DateTime checkOut,
      int guests,
    );

/// An [AiTool] for searching and booking hotels.
class SearchHotelTool extends AiTool<JsonMap> {
  /// Creates a [SearchHotelTool].
  SearchHotelTool({required this.onSearch})
    : super(
        name: 'searchHotel',
        description: 'Searches for a hotel based on the provided criteria.',
        parameters: S.object(
          properties: {
            'query': S.string(description: 'The search query for the hotel.'),
            'checkIn': S.string(description: 'The check-in date.'),
            'checkOut': S.string(description: 'The check-out date.'),
            'guests': S.integer(description: 'The number of guests.'),
          },
          required: ['query', 'checkIn', 'checkOut', 'guests'],
        ),
      );

  /// The callback to invoke when searching for a hotel.
  final SearchHotelCallback onSearch;

  @override
  Future<JsonMap> invoke(JsonMap args) async {
    final query = args['query'] as String;
    final checkIn = DateTime.parse(args['checkIn'] as String);
    final checkOut = DateTime.parse(args['checkOut'] as String);
    final guests = args['guests'] as int;

    return onSearch(query, checkIn, checkOut, guests);
  }
}
