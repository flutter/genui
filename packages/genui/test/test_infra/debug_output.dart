import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

void _saveToFile(String label, String extension, String Function() content) {
  if (!kDebugMode) return;
  final String timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  final dir = Directory('debug')..createSync(recursive: true);
  final file = File('${dir.path}/$timestamp-$label.$extension');
  file.writeAsStringSync(content());
  // ignore: avoid_print
  print('Saved $label to ${file.absolute.path}');
}

/// Saves [content] to a file and prints the file location to console.
void debugSaveTxt(String content, {String label = 'string'}) {
  _saveToFile(label, 'txt', () => content);
}

/// Saves [content] to a file and prints the file location to console.
void debugSaveJson(Object? content, {String label = 'object'}) {
  _saveToFile(
    label,
    'json',
    () => const JsonEncoder.withIndent('  ').convert(content),
  );
}
