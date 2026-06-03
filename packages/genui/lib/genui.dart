// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The generative UI framework (GenUI) for Flutter and Dart.
///
/// This library provides the necessary components to build generative user
/// interfaces in Flutter applications. It implements the A2UI protocol
/// (https://a2ui.org), and includes an object model for UI components,
/// data handling, and provides transport for communicating with generative AI
/// services (agents and LLMs).
library;

export 'src/catalog.dart';
export 'src/development_utilities.dart';
export 'src/engine.dart' hide SurfaceAdded, SurfaceRemoved;
export 'src/facade.dart';
export 'src/functions.dart';
export 'src/interfaces.dart';
export 'src/model.dart';
export 'src/primitives.dart';
export 'src/transport.dart';
export 'src/utils.dart';
export 'src/widgets.dart';
