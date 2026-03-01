import 'package:flutter_test/flutter_test.dart';

/// Verifies that the given [text] matches the content of the golden file.
///
/// If [autoUpdateGoldenFiles] is true, the golden file will be updated.
void verifyGoldenText(String text, String goldenFileName) {
  if (autoUpdateGoldenFiles) {}
}

/// Returns absolute path to the golden file.
///
/// The file resides in the directory, named as the test file, in the same directory as the test file.
///
/// For example, if the test file is `utils/my_main_test.dart`,
/// the golden file will be in `utils/my_main_test.golden/[file_name]`.
String _goldenFilePath(String fileName) {}
