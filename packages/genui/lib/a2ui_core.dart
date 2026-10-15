// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The A2UI protocol runtime that genui runs on: messages, surface and data
/// models, expressions, and reactivity.
///
/// This is genui's own copy of `package:a2ui_core` 0.1.0. Use these types,
/// not the ones from `package:a2ui_core`, for values passed to or received
/// from genui, such as the messages given to
/// `SurfaceController.handleMessage`.
library;

export 'src/a2ui_core/a2ui_core.dart';
