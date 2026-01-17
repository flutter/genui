// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The core library for the Flutter GenUI framework.
///
/// This library provides the necessary components to build generative user
/// interfaces in Flutter applications. It includes models for UI components,
/// data handling, and communication with a generative AI service.
library;

export 'src/catalog/core_catalog.dart';
export 'src/content_generator.dart';
export 'src/core/a2ui_message_processor.dart';
export 'src/core/genui_surface.dart';
export 'src/core/prompt_fragments.dart';
export 'src/core/ui_tools.dart';
export 'src/core/widget_utilities.dart';
export 'src/development_utilities/catalog_view.dart';
export 'src/facade/direct_call_integration/model.dart';
export 'src/facade/direct_call_integration/utils.dart';
export 'src/facade/gen_ui_conversation.dart';
export 'src/facade/widgets/chat_primitives.dart';
export 'src/model/a2ui_client_capabilities.dart';
export 'src/model/a2ui_message.dart';
export 'src/model/a2ui_schemas.dart';
export 'src/model/catalog.dart';
export 'src/model/catalog_item.dart';
export 'src/model/chat_message.dart';
export 'src/model/data_model.dart';
export 'src/model/tools.dart';
export 'src/model/ui_models.dart';
export 'src/primitives/logging.dart';
export 'src/primitives/simple_items.dart';
