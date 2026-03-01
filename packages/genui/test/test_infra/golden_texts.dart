import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies that the given [text] matches the content of the golden file.
///
/// If [autoUpdateGoldenFiles] is true, the golden file will be updated.
void verifyGoldenText(String text, String goldenFileName) {
  final String goldenFilePath = _goldenFilePath(goldenFileName);

  if (autoUpdateGoldenFiles) {
    File(goldenFilePath).writeAsStringSync(text);
  } else {
    final String goldenFileContent = File(goldenFilePath).readAsStringSync();
    expect(goldenFileContent, text);
  }
}

/// Returns absolute path to the golden file.
///
/// The file resides in the directory, named as the test file, in the same directory as the test file.
///
/// For example, if the test file is `utils/my_main_test.dart`,
/// the golden file will be in `utils/my_main_test.golden/[file_name]`.
String _goldenFilePath(String fileName) {
  final Uri scriptUri = Platform.script;
  final String scriptName = scriptUri.pathSegments.last;
  final String stem = scriptName.endsWith('.dart')
      ? scriptName.substring(0, scriptName.length - 5)
      : scriptName;
  final Uri goldenDir = scriptUri.resolve('$stem.golden/');
  return goldenDir.resolve(fileName).toFilePath();
}
