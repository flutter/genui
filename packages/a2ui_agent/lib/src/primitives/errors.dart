// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

/// Thrown when raw inference-format content cannot be compiled into A2UI
/// messages.
///
/// This covers lexical and syntactic failures (malformed JSON, invalid Express
/// statements) as well as catalog mismatches discovered while compiling.
class A2uiFormatError extends A2uiError {
  /// The 1-based line of the raw content the failure was detected on, if
  /// known.
  final int? line;

  /// The raw fragment that failed to compile, if known.
  final String? source;

  A2uiFormatError(String message, {this.line, this.source})
    : super(message, 'FORMAT_ERROR');

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType [$code]: $message');
    if (line != null) buffer.write(' (line $line)');
    if (source != null) buffer.write('\n  in: $source');
    return buffer.toString();
  }
}

/// Thrown when catalogs cannot be resolved against renderer capabilities.
class A2uiCapabilityError extends A2uiError {
  A2uiCapabilityError(String message) : super(message, 'CAPABILITY_ERROR');
}
