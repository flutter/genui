import 'package:file/file.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const excludedPackages = ['json_schema_builder'];

Future<List<Directory>> findPackages(Directory repoRoot) async {
  final Directory packagesDir = repoRoot.childDirectory('packages');
  if (!await packagesDir.exists()) {
    print('Error: packages directory not found at ${packagesDir.path}');
    return [];
  }

  final packages = <Directory>[];
  await for (final FileSystemEntity entity in packagesDir.list()) {
    if (entity is Directory) {
      final String packageName = p.basename(entity.path);
      if (excludedPackages.contains(packageName)) {
        print('Skipping excluded package: $packageName');
        continue;
      }
      final File pubspecFile = entity.childFile('pubspec.yaml');
      if (await pubspecFile.exists()) {
        packages.add(entity);
      }
    }
  }
  return packages;
}

Future<String> getPackageVersion(Directory packageDir) async {
  final File pubspecFile = packageDir.childFile('pubspec.yaml');
  final String content = await pubspecFile.readAsString();
  final yamlMap = loadYaml(content) as Map;
  return yamlMap['version'] as String;
}
