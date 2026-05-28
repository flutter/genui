// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/data_model.dart';

/// A facade over per-surface data models managed by
/// `a2ui_core.SurfaceGroupModel`.
///
/// Kept to preserve the legacy `SurfaceController.store` /
/// `store.getDataModel(surfaceId)` API. Pre-`createSurface`, returns a
/// standalone in-memory model; when `SurfaceController` later attaches a
/// live surface via [attachLive], any data written to the standalone model
/// is migrated into the live one and future [getDataModel] calls return the
/// live wrapper.
///
/// Slated for removal alongside the rest of the GenUI->a2ui_core facade
/// renames. New code should read from `SurfaceController.registry
/// .getSurface(id)?.dataModel` directly.
class DataModelStore {
  /// Creates a [DataModelStore].
  DataModelStore({DataModel? Function(String surfaceId)? lookup})
    : _lookup = lookup;

  final DataModel? Function(String surfaceId)? _lookup;
  final Map<String, DataModel> _dataModels = {};
  final Map<String, DataModel> _liveDataModels = {};
  final Set<String> _attachedSurfaces = {};

  /// Retrieves the data model for the given [surfaceId], creating it if it
  /// does not exist.
  DataModel getDataModel(String surfaceId) {
    final DataModel? liveModel = _lookup?.call(surfaceId);
    if (liveModel != null) {
      return _liveDataModels.putIfAbsent(surfaceId, () => liveModel);
    }
    return _dataModels.putIfAbsent(surfaceId, InMemoryDataModel.new);
  }

  /// Caches [liveModel] for [surfaceId] and migrates any pre-create
  /// fallback data into it. Callers that had a reference to the fallback
  /// model must refetch via [getDataModel].
  void attachLive(String surfaceId, DataModel liveModel) {
    final DataModel? fallback = _dataModels.remove(surfaceId);
    if (fallback != null) {
      final Object? snapshot = fallback.getValue<Object?>(DataPath.root);
      if (snapshot != null) {
        liveModel.update(DataPath.root, snapshot);
      }
      fallback.dispose();
    }
    _liveDataModels[surfaceId] = liveModel;
  }

  /// Removes the data model for the given [surfaceId] and detaches the surface.
  void removeDataModel(String surfaceId) {
    final DataModel? model = _dataModels.remove(surfaceId);
    model?.dispose();
    final DataModel? liveModel = _liveDataModels.remove(surfaceId);
    liveModel?.dispose();
    _attachedSurfaces.remove(surfaceId);
  }

  /// Marks the surface with the given [surfaceId] as attached.
  void attachSurface(String surfaceId) {
    _attachedSurfaces.add(surfaceId);
  }

  /// Marks the surface with the given [surfaceId] as detached.
  void detachSurface(String surfaceId) {
    _attachedSurfaces.remove(surfaceId);
  }

  /// An unmodifiable map of all registered data models.
  Map<String, DataModel> get dataModels =>
      Map.unmodifiable({..._dataModels, ..._liveDataModels});

  /// Disposes of all data models in this store.
  void dispose() {
    for (final DataModel model in _dataModels.values) {
      model.dispose();
    }
    for (final DataModel model in _liveDataModels.values) {
      model.dispose();
    }
    _dataModels.clear();
    _liveDataModels.clear();
  }
}
