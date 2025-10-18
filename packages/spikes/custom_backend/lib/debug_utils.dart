import 'dart:convert';
import 'dart:io';

int _i = 100;

void debugSaveToFile(String name, String content, {String extension = 'txt'}) {
  final d = DateTime.now();

  final dirName = 'debug/${d.year}-${d.month}-${d.day}_${d.hour}_${d.minute}';
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
