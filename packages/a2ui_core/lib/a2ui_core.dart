// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core A2UI protocol implementation for Dart.
library;

export 'src/common/cancellation.dart';
export 'src/common/data_path.dart';
// Common utilities.
export 'src/common/errors.dart';
// Event notifications for discrete lifecycle events.
export 'src/common/event_notifier.dart';
// Reactivity layer (extends listenable primitives with batch + computed).
export 'src/common/reactivity.dart';
// Protocol models.
export 'src/core/catalog.dart';
export 'src/core/common.dart';
export 'src/core/common_schemas.dart';
export 'src/core/component_model.dart';
// Rendering support.
export 'src/core/contexts.dart';
// State management.
export 'src/core/data_model.dart';
export 'src/core/messages.dart';
export 'src/core/minimal_catalog.dart';
export 'src/core/surface_model.dart';
// Listenable primitives from the shared notifier layer.
// ValueNotifier is intentionally excluded here because reactivity.dart provides
// an enhanced version with batch and dependency-tracking support.
export 'src/listenable/error_reporting.dart'
    show ListenableError, ListenableErrorDetails;
export 'src/listenable/notifiers.dart'
    show ChangeNotifier, GenUiListenable, GenUiValueListenable;
export 'src/listenable/primitives.dart' show VoidCallback;
export 'src/processing/basic_functions.dart';
export 'src/processing/expressions.dart';
// Processing & expressions.
export 'src/processing/processor.dart';
export 'src/rendering/binder.dart';
