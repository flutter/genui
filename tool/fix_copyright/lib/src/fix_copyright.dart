// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Fixes the copyright headers on various file types to conform with the Flutter
// repo copyright header. This is especially useful when updating platform
// runners that don't contain copyrights when generated.

import 'dart:async';
import 'dart:io';

import 'package:file/file.dart';

typedef LogFunction = void Function(String);

Future<int> fixCopyrights(
  FileSystem fileSystem, {
  required bool force,
  required String year,
  required List<String> paths,
  LogFunction? log,
  LogFunction? error,
}) async {
  final path = fileSystem.path;
  final extensionMap = _generateExtensionMap(year);
  void stdLog(String message) =>
      (log ?? stdout.writeln as LogFunction).call(message);
  void stdErr(String message) =>
      (error ?? stderr.writeln as LogFunction).call(message);

  String getExtension(File file) {
    final pathExtension = path.extension(file.path);
    return pathExtension.isNotEmpty ? pathExtension.substring(1) : '';
  }

  Iterable<File> matchingFiles(Directory dir) {
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => extensionMap.containsKey(getExtension(file)))
        .map((File file) => file.absolute);
  }

  final rest = paths.isEmpty ? <String>['.'] : paths;

  final files = <File>[];
  for (final fileOrDir in rest) {
    switch (fileSystem.typeSync(fileOrDir)) {
      case FileSystemEntityType.directory:
        files.addAll(matchingFiles(fileSystem.directory(fileOrDir)));
        break;
      case FileSystemEntityType.file:
        files.add(fileSystem.file(fileOrDir));
        break;
      case FileSystemEntityType.link:
      case FileSystemEntityType.notFound:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        // We don't care about these, just ignore them.
        break;
    }
  }

  final nonCompliantFiles = <File>[];
  for (final file in files) {
    try {
      final extension = getExtension(file);
      if (!extensionMap.containsKey(extension)) {
        stdErr(
          'Warning: File ${file.path} does not have an extension that requires '
          'a copyright header. Ignoring.',
        );
        continue;
      }
      final info = extensionMap[extension]!;
      final inputFile = file.absolute;
      var originalContents = inputFile.readAsStringSync();
      if (_hasCorrectLicense(originalContents, info)) {
        continue;
      }

      // If a sort-of correct copyright is there, but just doesn't have the
      // right case, date, spacing, license type or trailing newline, then
      // remove it.
      var newContents = originalContents.replaceFirst(
        RegExp(info.copyrightPattern, caseSensitive: false, multiLine: true),
        '',
      );
      // Strip any matching header from the existing file, and replace it with
      // the correct combined copyright and the header that was matched.
      if ((info.headerPattern ?? info.header) != null) {
        final match = RegExp(
          info.headerPattern ?? '(?<header>${RegExp.escape(info.header!)})',
          caseSensitive: false,
        ).firstMatch(newContents);
        if (match != null) {
          final header = match.namedGroup('header') ?? '';
          newContents = newContents.substring(match.end);
          newContents =
              '$header${info.copyright}\n${info.trailingBlank ? '\n' : ''}'
              '$newContents';
        } else {
          newContents = '${info.combined}$newContents';
        }
      } else {
        newContents = '${info.combined}$newContents';
      }
      if (newContents != originalContents) {
        if (force) {
          inputFile.writeAsStringSync(newContents);
        }
        nonCompliantFiles.add(file);
      }
    } on FileSystemException catch (e) {
      stdErr('Could not process file ${file.path}: $e');
    }
  }

  if (nonCompliantFiles.isNotEmpty) {
    stdErr(
      'Found ${nonCompliantFiles.length} files which have '
      'out-of-compliance copyrights.',
    );
    for (final file in nonCompliantFiles) {
      stdLog(fileSystem.path.canonicalize(file.path));
    }
    if (!force) {
      stdErr('\nRun with --force to update them.');
    } else {
      stdErr(
        '''\nAll files were given correct copyright notices, but please check them all manually. If a file had an out-of-compliance copyright that didn't match a known pattern, it may have been left intact, leaving a duplicate.''',
      );
    }
    return 1;
  }
  return 0;
}

class CopyrightInfo {
  CopyrightInfo(
    this.copyright, {
    required this.copyrightPattern,
    this.header,
    this.headerPattern,
    this.trailingBlank = true,
  }) : assert(!copyright.endsWith('\n'));

  final String copyright;
  final String copyrightPattern;
  final bool trailingBlank;
  final String? header;
  final String? headerPattern;

  RegExp get pattern {
    return RegExp(
      '${headerPattern ?? (header != null ? RegExp.escape(header!) : '')}'
      '${RegExp.escape(copyright)}\n${trailingBlank ? r'\n' : ''}',
    );
  }

  String get combined {
    String result;
    if (header != null && header!.isNotEmpty) {
      result = '$header$copyright';
    } else {
      result = copyright;
    }
    return trailingBlank ? '$result\n\n' : '$result\n';
  }

  @override
  String toString() {
    return '\n$runtimeType(copyright: "$copyright", copyrightPattern: '
        '"$copyrightPattern", header: "$header", headerPattern: '
        '"$headerPattern", trailingBlank: "$trailingBlank", '
        'combined: "$combined")';
  }
}

Map<String, CopyrightInfo> _generateExtensionMap(String year) {
  String generateCopyright({
    required String prefix,
    String suffix = '',
    required bool isParagraph,
  }) {
    return '''${prefix}Copyright $year The Flutter Authors. All rights reserved.${isParagraph ? '' : suffix}
${isParagraph ? '' : prefix}Use of this source code is governed by a BSD-style license that can be${isParagraph ? '' : suffix}
${isParagraph ? '' : prefix}found in the LICENSE file.$suffix''';
  }

  String generateCopyrightPattern({
    required String prefix,
    String suffix = '',
  }) {
    final escapedPrefix = RegExp.escape(prefix);
    final escapedSuffix = RegExp.escape(suffix);

    return '($escapedPrefix'
        r'Copyright (\d+) ([\w ]+)\.?\s+All rights reserved.'
        '(?:$escapedSuffix)?\\n'
        '(?:$escapedPrefix)?'
        r'Use of this source code is governed by a [-\w]+ license that can be'
        '(?:$escapedSuffix)?\\n'
        '(?:$escapedPrefix)?'
        r'found in the LICENSE file\.'
        '$escapedSuffix\\s*)';
  }

  CopyrightInfo generateInfo({
    required String prefix,
    String suffix = '',
    String? header,
    String? headerPattern,
    bool isParagraph = false,
    bool trailingBlank = true,
  }) {
    return CopyrightInfo(
      generateCopyright(
        prefix: prefix,
        suffix: suffix,
        isParagraph: isParagraph,
      ),
      copyrightPattern: generateCopyrightPattern(
        prefix: prefix,
        suffix: suffix,
      ),
      header: header,
      headerPattern: headerPattern,
      trailingBlank: trailingBlank,
    );
  }

  return <String, CopyrightInfo>{
    'bat': generateInfo(
      prefix: 'REM ',
      header: '@ECHO off\n',
      headerPattern: r'(?<header>@ECHO off\n)',
    ),
    'c': generateInfo(prefix: '// '),
    'cc': generateInfo(prefix: '// '),
    'cmake': generateInfo(prefix: '# '),
    'cpp': generateInfo(prefix: '// '),
    'dart': generateInfo(prefix: '// '),
    'gn': generateInfo(prefix: '# '),
    'gradle': generateInfo(prefix: '// '),
    'h': generateInfo(prefix: '// '),
    'html': generateInfo(
      prefix: '<!-- ',
      suffix: ' -->',
      isParagraph: true,
      trailingBlank: false,
      header: '<!DOCTYPE HTML>\n',
      headerPattern: r'(?<header><!DOCTYPE\s+HTML[^>]*>\n)?',
    ),
    'java': generateInfo(prefix: '// '),
    'kt': generateInfo(prefix: '// '),
    'm': generateInfo(prefix: '// '),
    'ps1': generateInfo(prefix: '# '),
    'sh': generateInfo(
      prefix: '# ',
      header: '#!/usr/bin/env bash\n',
      headerPattern:
          r'(?<header>#!/usr/bin/env bash\n|#!/bin/sh\n|#!/bin/bash\n)',
    ),
    'swift': generateInfo(prefix: '// '),
    'xml': generateInfo(
      prefix: '<!-- ',
      suffix: ' -->',
      isParagraph: true,
      headerPattern:
          r'''(?<header><\?xml\s+(?:version="1.0"\s+encoding="utf-8"|encoding="utf-8"\s+version="1.0")[^>]*\?>\n|)''',
    ),
    'yaml': generateInfo(prefix: '# '),
  };
}

bool _hasCorrectLicense(String rawContents, CopyrightInfo info) {
  // Normalize line endings.
  final contents = rawContents.replaceAll('\r\n', '\n');
  // Ignore empty files.
  return contents.isEmpty || contents.startsWith(info.pattern);
}
