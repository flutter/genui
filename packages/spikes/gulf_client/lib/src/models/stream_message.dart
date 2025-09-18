// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'component.dart';

sealed class GulfStreamMessage {
  factory GulfStreamMessage.fromJson(Map<String, dynamic> json) {
    // TODO(gspencer): implement fromJson
    throw UnimplementedError();
  }
}

class StreamHeader implements GulfStreamMessage {
  const StreamHeader({required this.version});

  final String version;
}

class BeginRendering implements GulfStreamMessage {
  const BeginRendering({required this.root, this.styles});

  final String root;
  final Map<String, dynamic>? styles;
}

class ComponentUpdate implements GulfStreamMessage {
  const ComponentUpdate({required this.components});

  final List<Component> components;
}

class DataModelUpdate implements GulfStreamMessage {
  const DataModelUpdate({this.path, required this.contents});

  final String? path;
  final dynamic contents;
}
