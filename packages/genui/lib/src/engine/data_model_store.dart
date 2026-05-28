// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/data_model.dart';

/// A facade over per-surface data models managed by
/// `a2ui_core.SurfaceGroupModel`.
///
/// Kept to preserve the legacy `SurfaceController.store` /
/// `store.getDataModel(surfaceId)` API. The lookup callback (provided by
/// `SurfaceController`) redirects active surfaces to the substrate's live
/// `surface.dataModel`; ids without a live surface fall back to a standalone
/// in-memory model, preserving the pre-migration "data survives before
/// createSurface" behavior.
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
