// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Core A2UI protocol implementation for Dart.
library a2ui_core;

// Listenable primitives from the shared notifier layer.
// ValueNotifier is intentionally excluded here because reactivity.dart provides
// an enhanced version with batch and dependency-tracking support.
export 'src/listenable/error_reporting.dart'
    show ListenableError, ListenableErrorDetails;
export 'src/listenable/notifiers.dart'
    show ChangeNotifier, GenUiListenable, GenUiValueListenable;
export 'src/listenable/primitives.dart' show VoidCallback;

// Reactivity layer (extends listenable primitives with batch + computed).
export 'src/common/reactivity.dart';

// Common utilities.
export 'src/common/errors.dart';
export 'src/common/cancellation.dart';
export 'src/common/data_path.dart';

// Protocol models.
export 'src/protocol/catalog.dart';
export 'src/protocol/messages.dart';
export 'src/protocol/common.dart';
export 'src/protocol/common_schemas.dart';
export 'src/protocol/minimal_catalog.dart';

// State management.
export 'src/state/data_model.dart';
export 'src/state/component_model.dart';
export 'src/state/surface_model.dart';

// Processing & expressions.
export 'src/processing/processor.dart';
export 'src/processing/expressions.dart';
export 'src/processing/basic_functions.dart';

// Rendering support.
export 'src/rendering/contexts.dart';
export 'src/rendering/binder.dart';
