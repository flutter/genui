// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'state_patcher.dart';
library;

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'data_type_validator.dart';

/// Manages the dynamic state of the FCP UI.
///
/// This class holds the state object and notifies listeners when it changes.
/// It also validates incoming state against the data types defined in the
/// catalog.
class FcpState with ChangeNotifier {
  /// Creates a new FcpState with an initial state object.
  ///
  /// The [validator] is used to validate data types against the [catalog].
  FcpState(this._state, {required this.validator, required this.catalog});

  Map<String, Object?> _state;

  /// The validator used to check data types against the catalog.
  final DataTypeValidator validator;

  /// The widget catalog containing data type definitions.
  final WidgetCatalog catalog;

  /// The current state object.
  Map<String, Object?> get state => _state;

  /// Sets a new state object and notifies listeners.
  ///
  /// This is used for wholesale replacement of the state. For partial updates,
  /// use [StatePatcher].
  set state(Map<String, Object?> newState) {
    _state = newState;
    notifyListeners();
  }

  /// Retrieves a value from the state using a dot-separated path.
  Object? getValue(String path) {
    final parts = path.split('.');
    Object? currentValue = _state;
    for (final part in parts) {
      if (currentValue is Map<String, Object?>) {
        currentValue = currentValue[part];
      } else {
        return null;
      }
    }
    return currentValue;
  }

  /// Validates a new state object against the catalog's data types.
  ///
  /// Returns `true` if all data types in the state are valid, `false`
  /// otherwise.
  Future<bool> validate(Map<String, Object?> newState) async {
    for (final entry in newState.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, Object?>) {
        if (!await validator.validate(
          dataType: key,
          data: value,
          catalog: catalog,
        )) {
          return false;
        }
      }
    }
    return true;
  }
}
