// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Integration package for GenUI and Dartantic AI.
///
/// This library provides a `DartanticContentGenerator` that implements
/// the GenUI `ContentGenerator` interface using the dartantic_ai package.
/// It supports multiple AI providers including OpenAI, Anthropic, Google,
/// Mistral, Cohere, and Ollama.
///
/// Example usage:
/// ```dart
/// import 'package:dartantic_ai/dartantic_ai.dart';
/// import 'package:genui/genui.dart';
/// import 'package:genui_dartantic/genui_dartantic.dart';
///
/// final catalog = CoreCatalogItems.asCatalog();
/// final manager = GenUiManager(catalog: catalog);
///
/// final contentGenerator = DartanticContentGenerator(
///   provider: Providers.google,
///   catalog: catalog,
///   systemInstruction: 'You are a helpful assistant...',
/// );
///
/// final conversation = GenUiConversation(
///   contentGenerator: contentGenerator,
///   genUiManager: manager,
/// );
/// ```
library;

export 'src/dartantic_content_converter.dart';
export 'src/dartantic_content_generator.dart';
export 'src/dartantic_schema_adapter.dart';
