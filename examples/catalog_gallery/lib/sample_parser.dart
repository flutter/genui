// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:genui/genui.dart';
import 'package:yaml/yaml.dart';

class Sample {
  final String name;
  final String description;
  final Stream<A2uiMessage> messages;

  Sample({
    required this.name,
    required this.description,
    required this.messages,
  });
}

class SampleParser {
  static Future<Sample> parseFile(File file) async {
    final String content = await file.readAsString();
    return parseString(content);
  }

  static Sample parseString(String content) {
    final List<String> lines = const LineSplitter().convert(content);
    var startLine = 0;
    if (lines.isNotEmpty && lines.first.trim() == '---') {
      startLine = 1;
    }

    final int separatorIndex = lines.indexOf('---', startLine);

    if (separatorIndex == -1) {
      throw const FormatException(
        'Sample file must contain a YAML header and a JSONL body separated '
        'by "---"',
      );
    }

    final String yamlHeader = lines
        .sublist(startLine, separatorIndex)
        .join('\n');
    final String jsonlBody = lines.sublist(separatorIndex + 1).join('\n');

    final dynamic yamlNode = loadYaml(yamlHeader);
    final Map<dynamic, dynamic> header = (yamlNode is Map) ? yamlNode : {};
    final String name = header['name'] as String? ?? 'Untitled Sample';
    final String description = header['description'] as String? ?? '';

    final Stream<A2uiMessage> messages = Stream.fromIterable(
      const LineSplitter()
          .convert(jsonlBody)
          .where((line) => line.trim().isNotEmpty)
          .map((line) {
            final dynamic json = jsonDecode(line);
            if (json is Map<String, dynamic>) {
              return A2uiMessage.fromJson(json);
            }
            throw FormatException('Invalid JSON line: $line');
          }),
    );

    return Sample(name: name, description: description, messages: messages);
  }
}
