// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_client/src/core/interpreter.dart';
import 'package:a2ui_client/src/models/component.dart';
import 'package:flutter/foundation.dart';

class FakeA2uiInterpreter extends ChangeNotifier implements A2uiInterpreter {
  final Map<String, Object?> _data = {};

  void onResolveDataBinding(String path, Object? value) {
    _data[path] = value;
  }

  @override
  void updateData(String path, dynamic value) {
    _data[path] = value;
  }

  @override
  Object? resolveDataBinding(String path) {
    return _data[path];
  }

  @override
  String? get error => throw UnimplementedError();

  @override
  bool get isReadyToRender => throw UnimplementedError();

  @override
  void processMessage(String jsonl) {
    throw UnimplementedError();
  }

  @override
  String? get rootComponentId => throw UnimplementedError();

  @override
  Stream<String> get stream => throw UnimplementedError();

  @override
  Component? getComponent(String id) {
    throw UnimplementedError();
  }
}
