// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/data_model.dart';

/// Manages the data models for surfaces.
class DataModelStore {
  final Map<String, DataModel> _dataModels = {};
  final Set<String> _attachedSurfaces = {};

  DataModel getDataModel(String surfaceId) {
    return _dataModels.putIfAbsent(surfaceId, DataModel.new);
  }

  void removeDataModel(String surfaceId) {
    final DataModel? model = _dataModels.remove(surfaceId);
    model?.dispose();
    _attachedSurfaces.remove(surfaceId);
  }

  void attachSurface(String surfaceId) {
    _attachedSurfaces.add(surfaceId);
  }

  void detachSurface(String surfaceId) {
    _attachedSurfaces.remove(surfaceId);
  }

  Map<String, Object?> getClientDataSnapshot() {
    final result = <String, Object?>{};
    for (final String surfaceId in _attachedSurfaces) {
      if (_dataModels.containsKey(surfaceId)) {
        result[surfaceId] = _dataModels[surfaceId]!.data;
      }
    }
    return {'version': 'v0.9', 'surfaces': result};
  }

  Map<String, DataModel> get dataModels => Map.unmodifiable(_dataModels);

  void dispose() {
    for (final DataModel model in _dataModels.values) {
      model.dispose();
    }
  }
}
