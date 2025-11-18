// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A library for building Agent-to-Agent (A2A) clients.
library;

// Client exports.
export 'src/client/a2a_client.dart';
export 'src/client/a2a_exception.dart';
export 'src/client/http_transport.dart';
export 'src/client/sse_transport.dart';
export 'src/client/transport.dart';
export 'src/core/agent_capabilities.dart';
// Core data models and exceptions.
export 'src/core/agent_card.dart';
export 'src/core/events.dart';
export 'src/core/list_tasks_params.dart';
export 'src/core/list_tasks_result.dart';
export 'src/core/message.dart';
export 'src/core/part.dart';
export 'src/core/push_notification.dart';
export 'src/core/security_scheme.dart';
export 'src/core/task.dart';
