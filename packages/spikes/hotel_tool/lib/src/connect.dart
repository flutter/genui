// https://serpapi.com/google-hotels-api
import 'dart:convert';

import 'package:http/http.dart' as http;

class SerpConnect {
  final String apiKey;

  SerpConnect(this.apiKey);

  Future<Map<String, Object?>> fetchHotelData(String query) async {
    final url = Uri.https('serpapi.com', '/search', {
      'engine': 'google_hotels',
      'q': query,
      'api_key': apiKey,
      'check_in_date': '2025-09-15',
      'check_out_date': '2025-09-16',
    });

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, Object?>;
    } else {
      throw Exception(
        'Failed to load hotel data: ${response.statusCode} ${response.body}',
      );
    }
  }
}
