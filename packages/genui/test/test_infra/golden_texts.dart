import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies that the given [text] matches the content of the golden file.
///
/// If [autoUpdateGoldenFiles] is true, the golden file will be updated.
///
/// The file resides in the directory, named as the test file, located
/// in the same directory as the test file.
/// For example, if the test file is `utils/my_main_test.dart`,
/// the golden file will be in `utils/my_main_test.golden/[file_name]`.
void verifyGoldenText(String text, String goldenFileName) {
  final String goldenFilePath = _goldenFilePath(goldenFileName);

  if (autoUpdateGoldenFiles) {
    File(goldenFilePath).writeAsStringSync(text);
  } else {
    final String goldenFileContent;
    try {
      goldenFileContent = File(goldenFilePath).readAsStringSync();
    } on PathNotFoundException {
      fail(
        'Golden file not found: $goldenFilePath\n'
        'Run with --update-goldens to create it.',
      );
    }
    expect(goldenFileContent, text);
  }
}

/// Returns absolute path to the golden file.

/// Extracts the test file URI from the call stack, skipping frames from
/// this file.
Uri _testFileUri() {
  // Frame format: "#N      name (uri:line:col)"
  final framePattern = RegExp(r'\((.+\.dart):\d+:\d+\)$');
  for (final String frame in StackTrace.current.toString().split('\n')) {
    final RegExpMatch? match = framePattern.firstMatch(frame.trim());
    if (match == null) continue;
    final Uri? uri = Uri.tryParse(match.group(1)!);
    if (uri == null) continue;
    if (uri.pathSegments.last == 'golden_texts.dart') continue;
    return uri;
  }
  throw StateError('Could not determine test file URI from stack trace');
}

String _goldenFilePath(String fileName) {
  final Uri testUri = _testFileUri();
  final String scriptName = testUri.pathSegments.last;
  final String stem = scriptName.endsWith('.dart')
      ? scriptName.substring(0, scriptName.length - 5)
      : scriptName;
  final Uri goldenDir = testUri.resolve('$stem.golden/');
  return goldenDir.resolve(fileName).toFilePath();
}
