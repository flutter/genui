// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core A2UI protocol implementation for Dart.
library;

// Protocol models.
export 'core/catalog.dart';
export 'core/common.dart';
export 'core/common_schemas.dart';
export 'core/component_model.dart';
// Rendering support.
export 'core/contexts.dart';
// State management.
export 'core/data_model.dart';
export 'core/messages.dart';
export 'core/minimal_catalog.dart';
export 'core/surface_group_model.dart';
export 'core/surface_model.dart';
export 'primitives/cancellation.dart';
export 'primitives/data_path.dart';
export 'primitives/errors.dart';
// Event notifications for discrete lifecycle events.
export 'primitives/event_notifier.dart';
// Reactivity (re-exports preact_signals primitives).
export 'primitives/reactivity.dart';
export 'processing/basic_functions.dart';
export 'processing/expressions.dart';
// Processing & expressions.
export 'processing/processor.dart';
export 'rendering/binder.dart';
