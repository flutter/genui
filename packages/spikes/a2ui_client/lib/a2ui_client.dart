// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A client for the A2UI Streaming UI Protocol.
///
/// This library provides the necessary components to render a Flutter UI
/// from a JSON-based definition provided by a server.
library;

export 'src/core/a2ui_agent_connector.dart';
export 'src/core/interpreter.dart';
export 'src/core/widget_registry.dart';
export 'src/models/chat_message.dart';
export 'src/models/component.dart';
export 'src/models/stream_message.dart';
export 'src/utils/logger.dart';
export 'src/widgets/a2ui_provider.dart';
export 'src/widgets/a2ui_view.dart';
export 'src/widgets/component_properties_visitor.dart';
