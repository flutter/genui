// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart' show XFile;
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
// ignore: implementation_imports
import 'package:mime/src/default_extension_map.dart';
import 'package:path/path.dart' as p;

import '../model.dart';

final class _Json {
  static const content = 'content';
  static const mimeType = 'mimeType';
  static const name = 'name';
  static const bytes = 'bytes';
}

/// A data part containing binary data (e.g., images).
@immutable
final class DataPart extends Part {
  static const type = 'Data';

  /// Creates a new data part.
  DataPart(this.bytes, {required this.mimeType, String? name})
    : name = name ?? nameFromMimeType(mimeType);

  /// Creates a data part from a JSON-compatible map.
  factory DataPart.fromJson(Map<String, Object?> json) {
    final content = json[_Json.content] as Map<String, Object?>;
    final dataUri = content[_Json.bytes] as String;
    final Uri uri = Uri.parse(dataUri);
    return DataPart(
      uri.data!.contentAsBytes(),
      mimeType: content[_Json.mimeType] as String,
      name: content[_Json.name] as String?,
    );
  }

  /// Creates a data part from an [XFile].
  static Future<DataPart> fromFile(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    final String? name = _nameFromPath(file.path) ?? _emptyNull(file.name);
    final String mimeType =
        _emptyNull(file.mimeType) ??
        mimeTypeForFile(
          name ?? '',
          headerBytes: Uint8List.fromList(
            bytes.take(defaultMagicNumbersMaxLength).toList(),
          ),
        );

    return DataPart(bytes, mimeType: mimeType, name: name);
  }

  static String? _nameFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final Uri? url = Uri.tryParse(path);
    if (url == null) return p.basename(path);
    final List<String> segments = url.pathSegments;
    if (segments.isEmpty) return null;
    return segments.last;
  }

  static String? _emptyNull(String? value) =>
      value == null || value.isEmpty ? null : value;

  /// The binary data.
  final Uint8List bytes;

  /// The MIME type of the data.
  final String mimeType;

  /// Optional name for the data.
  final String? name;

  @override
  Map<String, Object?> toJson() => {
    Part.typeKey: type,
    _Json.content: {
      if (name != null) _Json.name: name,
      _Json.mimeType: mimeType,
      _Json.bytes: 'data:$mimeType;base64,${base64Encode(bytes)}',
    },
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    const deepEquality = DeepCollectionEquality();
    return other is DataPart &&
        deepEquality.equals(other.bytes, bytes) &&
        other.mimeType == mimeType &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(mimeType, name, Object.hashAll(bytes));

  @override
  String toString() =>
      'DataPart(mimeType: $mimeType, name: $name, bytes: ${bytes.length})';

  @visibleForTesting
  static const defaultMimeType = 'application/octet-stream';

  /// Gets the MIME type for a file.
  @visibleForTesting
  static String mimeTypeForFile(String path, {Uint8List? headerBytes}) =>
      lookupMimeType(path, headerBytes: headerBytes) ?? defaultMimeType;

  /// Gets the name for a MIME type.
  @visibleForTesting
  static String nameFromMimeType(String mimeType) {
    final String ext = extensionFromMimeType(mimeType) ?? 'bin';
    return mimeType.startsWith('image/') ? 'image.$ext' : 'file.$ext';
  }

  /// Gets the extension for a MIME type.
  @visibleForTesting
  static String? extensionFromMimeType(String mimeType) {
    final String ext = defaultExtensionMap.entries
        .firstWhere(
          (e) => e.value == mimeType,
          orElse: () => const MapEntry('', ''),
        )
        .key;
    return ext.isNotEmpty ? ext : null;
  }
}
