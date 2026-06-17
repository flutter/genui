// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A platform-agnostic reference to a single sample.
///
/// Holds the display [name] of the sample and a [load] callback that returns
/// the raw `.sample` file contents. The loader hides where the sample comes
/// from (a bundled asset on web/desktop, or a file on disk when a `--samples`
/// directory override is supplied on desktop), so `SamplesView` never depends
/// on `dart:io`.
class SampleRef {
  const SampleRef({required this.name, required this.load});

  /// The display name (the file name without its `.sample` extension).
  final String name;

  /// Loads the raw contents of the sample.
  final Future<String> Function() load;
}

/// A source of [SampleRef]s.
abstract class SampleSource {
  /// Returns the available samples, sorted by display name.
  Future<List<SampleRef>> listSamples();
}

/// Loads samples bundled with the app as assets under `samples/`.
///
/// Works on every platform (including web) because it reads through the
/// [rootBundle] asset bundle rather than the filesystem.
class AssetSampleSource implements SampleSource {
  const AssetSampleSource();

  static const String _prefix = 'samples/';
  static const String _suffix = '.sample';

  @override
  Future<List<SampleRef>> listSamples() async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    final List<SampleRef> refs = manifest
        .listAssets()
        .where((key) => key.startsWith(_prefix) && key.endsWith(_suffix))
        .map(
          (key) => SampleRef(
            name: _displayName(key),
            load: () => rootBundle.loadString(key),
          ),
        )
        .toList();
    refs.sort((a, b) => a.name.compareTo(b.name));
    return refs;
  }

  static String _displayName(String assetKey) {
    final String fileName = assetKey.split('/').last;
    return fileName.substring(0, fileName.length - _suffix.length);
  }
}

/// Loads samples from a directory on disk.
///
/// Desktop/mobile only: this relies on `dart:io` filesystem access (via the
/// `file` package) and must never be used on web. Used for the `--samples`
/// override and by tests that supply an in-memory filesystem.
class DirectorySampleSource implements SampleSource {
  DirectorySampleSource(this.directory) : assert(!kIsWeb);

  final Directory directory;

  @override
  Future<List<SampleRef>> listSamples() async {
    if (!directory.existsSync()) {
      return const <SampleRef>[];
    }
    final List<File> files = (await directory.list().toList())
        .whereType<File>()
        .where((file) => file.path.endsWith('.sample'))
        .toList();
    final List<SampleRef> refs = files
        .map(
          (file) => SampleRef(
            name: directory.fileSystem.path.basenameWithoutExtension(
              file.path,
            ),
            load: file.readAsString,
          ),
        )
        .toList();
    refs.sort((a, b) => a.name.compareTo(b.name));
    return refs;
  }
}
