// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../model/data_model.dart';

/// A compatibility facade over the per-surface data models managed by
/// `a2ui_core.SurfaceGroupModel`.
///
/// Earlier `package:genui` releases kept a separate per-surface
/// `InMemoryDataModel` registry here, distinct from anything the substrate
/// owned. Post-`a2ui_core` migration, the canonical data model lives on
/// `core.SurfaceModel.dataModel`; this class exists to preserve the old
/// public API (`SurfaceController.store`, `store.getDataModel(surfaceId)`)
/// while transparently returning a [DataModel] wrapper over the live
/// substrate model.
///
/// The [lookup] callback is what does the substrate redirection: GenUI's
/// own `SurfaceController` constructs the store with a lookup that returns
/// `InMemoryDataModel.wrap(surface.dataModel)` for active surfaces. When
/// no live surface exists for a requested id, [getDataModel] falls back to
/// a standalone in-memory model — preserving the prior "data survives
/// before createSurface" leniency that some integration paths relied on.
///
/// This class will be removed in the same follow-up PR that renames the
/// rest of GenUI's facade types to match `a2ui_core` directly; new code
/// should prefer reading from the surface's own data model via
/// `SurfaceController.registry.getSurface(id)?.dataModel`.
class DataModelStore {
  /// Creates a [DataModelStore].
  ///
  /// When [lookup] returns a model for a surface, that live model is used
  /// instead of creating a standalone fallback model. This keeps the legacy
  /// store API source-compatible while GenUI's own controller stores data in
  /// the a2ui_core-backed surface model.
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
