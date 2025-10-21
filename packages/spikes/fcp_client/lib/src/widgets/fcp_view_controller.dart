// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

///@docImport 'fcp_view.dart';
library;

import 'dart:async';

import '../models/models.dart';

/// A controller to programmatically interact with an [FcpView].
///
/// This allows for sending targeted updates (state or layout) to the view
/// from outside the FCP event loop, enabling integration with other parts of
/// an application, such as a native backend or a separate state management
/// solution.
class FcpViewController {
  final _stateUpdateController = StreamController<StateUpdate>.broadcast();
  final _layoutUpdateController = StreamController<LayoutUpdate>.broadcast();

  /// A stream of [StateUpdate] payloads to be applied to the view.
  /// The [FcpView] listens to this stream and applies the patches accordingly.
  Stream<StateUpdate> get onStateUpdate => _stateUpdateController.stream;

  /// A stream of [LayoutUpdate] payloads to be applied to the view.
  /// The [FcpView] listens to this stream and applies the patches accordingly.
  Stream<LayoutUpdate> get onLayoutUpdate => _layoutUpdateController.stream;

  /// Sends a [StateUpdate] to the controlled [FcpView] to apply a patch to
  /// the UI's state.
  void patchState(StateUpdate update) {
    _stateUpdateController.add(update);
  }

  /// Sends a [LayoutUpdate] to the controlled [FcpView] to apply a patch to
  /// the UI's structure.
  void patchLayout(LayoutUpdate update) {
    _layoutUpdateController.add(update);
  }

  /// Disposes the controller and closes the underlying streams.
  /// This should be called when the controller is no longer needed, to prevent
  /// memory leaks.
  void dispose() {
    _stateUpdateController.close();
    _layoutUpdateController.close();
  }
}
