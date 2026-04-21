// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';
import 'package:flutter/foundation.dart';

/// Extension to convert [GenUiListenable] to [Listenable].
///
/// Enables using [GenUiListenable] with Flutter widgets
/// that accept [Listenable].
extension FlutterListenable on GenUiListenable {
  Listenable listenable() {
    return FlutterListenableAdapter(this);
  }
}

/// Extensions to convert GenUi value listenables to Flutter value listenables.
extension GenUiValueListenableFlutterExtension<T> on GenUiValueListenable<T> {
  /// Converts this [GenUiValueListenable] to a Flutter [ValueListenable].
  ValueListenable<T> valueListenable() =>
      FlutterValueListenableAdapter<T>(this);
}

class FlutterListenableAdapter implements Listenable {
  FlutterListenableAdapter(this._listenable);

  final GenUiListenable _listenable;

  @override
  void addListener(VoidCallback listener) {
    _listenable.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listenable.removeListener(listener);
  }
}

class FlutterValueListenableAdapter<T> extends FlutterListenableAdapter
    implements ValueListenable<T> {
  FlutterValueListenableAdapter(GenUiValueListenable<T> super.listenable);

  GenUiValueListenable<T> get _valueListenable =>
      _listenable as GenUiValueListenable<T>;

  @override
  T get value => _valueListenable.value;
}
