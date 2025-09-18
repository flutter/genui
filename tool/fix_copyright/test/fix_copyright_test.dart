// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:fix_copyright/fix_copyright.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late List<String> log;
  late List<String> error;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    log = <String>[];
    error = <String>[];
  });

  Future<int> runFixCopyrights({
    List<String> paths = const <String>['.'],
    String year = '2025',
    bool force = false,
  }) async {
    return fixCopyrights(
      fileSystem,
      force: force,
      year: year,
      paths: paths,
      log: log.add,
      error: error.add,
    );
  }

  test('dry run lists non-compliant files and exits with 1', () async {
    // Create test files
    fileSystem.file('compliant.dart').createSync();
    fileSystem.file('compliant.dart').writeAsStringSync('''
// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main() {}
''');
    final nonCompliantFile = fileSystem.file('non_compliant.dart')
      ..createSync()
      ..writeAsStringSync('void main() {}');
    final incorrectYearFile = fileSystem.file('incorrect_year.dart')
      ..createSync()
      ..writeAsStringSync('''
// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main() {}
''');
    fileSystem.file('unsupported.txt')
      ..createSync()
      ..writeAsStringSync('some text');
    fileSystem.file('empty.dart').createSync();
    fileSystem.directory('subdir').createSync();
    final subDirFile = fileSystem.file('subdir/non_compliant.java')
      ..createSync()
      ..writeAsStringSync('class MyClass {}');

    final exitCode = await runFixCopyrights();

    expect(exitCode, 1);

    // Check that files were not modified
    expect(nonCompliantFile.readAsStringSync(), 'void main() {}');
    expect(incorrectYearFile.readAsStringSync(), contains('// Copyright 2020'));
    expect(subDirFile.readAsStringSync(), 'class MyClass {}');
  });

  test('--force updates non-compliant files', () async {
    final compliantContent = '''
// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main() {}
''';
    final compliantFile = fileSystem.file('compliant.dart')
      ..createSync()
      ..writeAsStringSync(compliantContent);
    final nonCompliantFile = fileSystem.file('non_compliant.dart')
      ..createSync()
      ..writeAsStringSync('void main() {}');
    final incorrectYearFile = fileSystem.file('incorrect_year.dart')
      ..createSync()
      ..writeAsStringSync('''
// Copyright 2020 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main() {}
''');
    final emptyFile = fileSystem.file('empty.dart')..createSync();

    final exitCode = await runFixCopyrights(force: true);

    expect(exitCode, 1);

    // Check that files were modified
    expect(
      nonCompliantFile.readAsStringSync(),
      startsWith('// Copyright 2025'),
    );
    expect(
      incorrectYearFile.readAsStringSync(),
      startsWith('// Copyright 2025'),
    );

    // Check that compliant and empty files were not modified
    expect(compliantFile.readAsStringSync(), compliantContent);
    expect(emptyFile.readAsStringSync(), isEmpty);
  });

  test('--force updates files with existing headers', () async {
    final shellScript = fileSystem.file('test.sh')
      ..createSync()
      ..writeAsStringSync('''
#!/bin/bash
# Copyright 2020 The Flutter Authors.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
echo "Hello"
''');

    final htmlFile = fileSystem.file('test.html')
      ..createSync()
      ..writeAsStringSync('''
<!DOCTYPE html>
<html>
<head><title>Test</title></head>
<body></body>
</html>
''');

    final xmlFile = fileSystem.file('test.xml')
      ..createSync()
      ..writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<root></root>
''');

    final exitCode = await runFixCopyrights(force: true);
    expect(exitCode, 1);

    final newShellContent = shellScript.readAsStringSync();
    expect(
      newShellContent,
      startsWith('''#!/bin/bash
# Copyright 2025'''),
    );
    expect(newShellContent, endsWith('echo "Hello"\n'));

    final newHtmlContent = htmlFile.readAsStringSync();
    expect(
      newHtmlContent,
      startsWith('''<!DOCTYPE html>
<!-- Copyright 2025'''),
    );
    expect(newHtmlContent, endsWith('</html>\n'));

    final newXmlContent = xmlFile.readAsStringSync();
    expect(
      newXmlContent,
      startsWith('''<?xml version="1.0" encoding="utf-8"?>
<!-- Copyright 2025'''),
    );
    expect(newXmlContent, endsWith('<root></root>\n'));
  });

  test('exits 0 when no non-compliant files are found', () async {
    fileSystem.file('compliant.dart')
      ..createSync()
      ..writeAsStringSync('''
// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main() {}
''');
    fileSystem.file('empty.dart').createSync();
    fileSystem.file('unsupported.txt')
      ..createSync()
      ..writeAsStringSync('foo');

    final exitCode = await runFixCopyrights();

    expect(exitCode, 0);
  });

  test('works with specific file arguments', () async {
    final nonCompliant1 = fileSystem.file('non_compliant1.dart')
      ..createSync()
      ..writeAsStringSync('// no copyright');
    final nonCompliant2 = fileSystem.file('non_compliant2.dart')
      ..createSync()
      ..writeAsStringSync('// no copyright');
    fileSystem.file('non_compliant3.dart')
      ..createSync()
      ..writeAsStringSync('// no copyright');

    final exitCode = await runFixCopyrights(
      paths: [nonCompliant1.path, nonCompliant2.path],
    );

    expect(exitCode, 1);
  });

  test('does not duplicate headers', () async {
    final htmlFile = fileSystem.file('test.html')
      ..createSync()
      ..writeAsStringSync('''
<!DOCTYPE html>
<!-- Copyright 2025 The Flutter Authors.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file. -->
<html>
<head><title>Test</title></head>
<body></body>
</html>
''');

    final exitCode = await runFixCopyrights(force: true);
    expect(exitCode, 0);

    final newHtmlContent = htmlFile.readAsStringSync();
    expect(
      newHtmlContent,
      startsWith('''<!DOCTYPE html>
<!-- Copyright 2025'''),
    );
    expect(newHtmlContent, endsWith('</html>\n'));
    // There shouldn't be more than one instance of the copyright.
    expect(newHtmlContent.split('Copyright 2025').length, 2);
  });
}
