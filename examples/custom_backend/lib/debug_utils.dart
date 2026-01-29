// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:convert/convert.dart';

int _i = 100;

void debugSaveToFile(String name, String content, {String extension = 'txt'}) {
  final dirName =
      'debug/${FixedDateTimeFormatter('YYYY-MM-DD_hh_mm_ss').encode(DateTime.now())}';
  final directory = Directory(dirName);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  final file = File('$dirName/${_i++}-$name.log.$extension');
  file.writeAsStringSync(content);
  print('Debug: ${Directory.current.path}/${file.path}');
}

void debugSaveToFileObject(String name, Object? content) {
  final encoder = const JsonEncoder.withIndent('  ');
  final String prettyJson = encoder.convert(content);
  debugSaveToFile(name, prettyJson, extension: 'json');
}
