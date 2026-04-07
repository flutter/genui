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
