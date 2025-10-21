// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Fixes the copyright headers on various file types to conform with the Flutter
// repo copyright header. This is especially useful when updating platform
// runners that don't contain copyrights when generated.

import 'dart:async';
import 'dart:io';

import 'package:file/file.dart';
import 'package:process/process.dart';

typedef LogFunction = void Function(String);

Future<int> fixCopyrights(
  FileSystem fileSystem, {
  required bool force,
  required String year,
  required List<String> paths,
  ProcessManager processManager = const LocalProcessManager(),
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

  final gitRootResult = await processManager.run([
    'git',
    'rev-parse',
    '--show-toplevel',
  ]);
  if (gitRootResult.exitCode != 0) {
    stdErr(
      'Error: not a git repository. '
      'This tool only works within a git repository.',
    );
    return 1;
  }
  final repoRoot = gitRootResult.stdout.toString().trim();

  final gitFilesResult = await processManager.run([
    'git',
    'ls-files',
    ...paths,
  ], workingDirectory: repoRoot);

  if (gitFilesResult.exitCode != 0) {
    stdErr('Error running "git ls-files":\n${gitFilesResult.stderr}');
    return 1;
  }

  final files = gitFilesResult.stdout
      .toString()
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .map((filePath) => fileSystem.file(path.join(repoRoot, filePath)))
      .where((file) => extensionMap.containsKey(getExtension(file)))
      .toList();

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
      final originalContents = inputFile.readAsStringSync();
      if (_hasCorrectLicense(originalContents, info)) {
        continue;
      }

      nonCompliantFiles.add(file);

      if (force) {
        var contents = originalContents.replaceAll('\r\n', '\n');
        String? fileHeader;
        if (info.headerPattern != null) {
          final match = RegExp(
            info.headerPattern!,
            caseSensitive: false,
          ).firstMatch(contents);
          if (match != null && match.start == 0) {
            fileHeader = match.group(0);
            contents = contents.substring(match.end);
          }
        }

        contents = contents.trimLeft();

        // If a sort-of correct copyright is there, but just doesn't have the
        // right case, date, spacing, license type or trailing newline, then
        // remove it.
        contents = contents.replaceFirst(
          RegExp(info.copyrightPattern, caseSensitive: false, multiLine: true),
          '',
        );
        contents = contents.trimLeft();
        var newContents = '';
        if (fileHeader != null) {
          final copyrightBlock =
              '${info.copyright}${info.trailingBlank ? '\n\n' : '\n'}';
          newContents = '$fileHeader$copyrightBlock$contents';
        } else {
          newContents = '${info.combined}$contents';
        }

        if (newContents != originalContents.replaceAll('\r\n', '\n')) {
          inputFile.writeAsStringSync(newContents);
        }
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
      '^(?:${headerPattern ?? (header != null ? RegExp.escape(header!) : '')})?'
      '${RegExp.escape(copyright)}\n${trailingBlank ? r'\n' : ''}',
      multiLine: true,
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
    return '''${prefix}Copyright $year The Flutter Authors.${isParagraph ? '' : suffix}
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
        r'Copyright (\d+) ([\w ]+)\.?(?:\s*All rights reserved.)?'
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
    'dart': generateInfo(prefix: '// ', headerPattern: r'(?<header>#!.*\n?)'),
    'gn': generateInfo(prefix: '# '),
    'gradle': generateInfo(prefix: '// '),
    'h': generateInfo(prefix: '// '),
    'html': generateInfo(
      prefix: '<!-- ',
      suffix: ' -->',
      isParagraph: true,
      trailingBlank: false,
      header: '<!DOCTYPE HTML>\n',
      headerPattern: r'(?<header><!DOCTYPE\s+HTML[^>]*>\n?)?',
    ),
    'js': generateInfo(prefix: '// '),
    'java': generateInfo(prefix: '// '),
    'kt': generateInfo(prefix: '// '),
    'm': generateInfo(prefix: '// '),
    'ps1': generateInfo(prefix: '# '),
    'sh': generateInfo(prefix: '# ', headerPattern: r'(?<header>#!.*\n?)'),
    'swift': generateInfo(prefix: '// '),
    'ts': generateInfo(prefix: '// '),
    'xml': generateInfo(
      prefix: '<!-- ',
      suffix: ' -->',
      isParagraph: true,
      headerPattern:
          r'''(?<header><\?xml\s+(?:version="1.0"\s+encoding="utf-8"|encoding="utf-8"\s+version="1.0")[^>]*\?>\n?|)''',
    ),
    'yaml': generateInfo(prefix: '# '),
  };
}

bool _hasCorrectLicense(String rawContents, CopyrightInfo info) {
  // Normalize line endings.
  var contents = rawContents.replaceAll('\r\n', '\n');
  // Ignore empty files.
  if (contents.isEmpty) {
    return true;
  }
  return info.pattern.hasMatch(contents);
}
