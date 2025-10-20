// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

int _i = 100;

final _formatter = DateFormat('yyyy-MM-dd_HH_mm_ss');

void debugSaveToFile(String name, String content, {String extension = 'txt'}) {
  final dirName = 'debug/${_formatter.format(DateTime.now())}';
  final directory = Directory(dirName);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  final file = File('$dirName/${_i++}-$name.log.$extension');
  file.writeAsStringSync(content);
  print('Debug: ${Directory.current.path}/${file.path}');
}

void debugSaveToFileObject(String name, dynamic content) {
  final encoder = const JsonEncoder.withIndent('  ');
  final prettyJson = encoder.convert(content);
  debugSaveToFile(name, prettyJson, extension: 'json');
}
