import 'dart:convert';

import 'package:hotel_tool/hotel_tool.dart';
import 'api_key.dart';

Future<void> main(List<String> arguments) async {
  final connect = SerpConnect(apiKey);

  final data = await connect.fetchHotelData('Molokai, Hawaii');

  print(formatJson(data));
}

String formatJson(Map<String, Object?> json) {
  return const JsonEncoder.withIndent('  ').convert(json);
}
