// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The A2UI agent SDK.
///
/// This package gives an agent everything it needs between "the model is about
/// to be called" and "the renderer receives A2UI": catalog management,
/// capability negotiation, prompt engineering, response parsing and payload
/// validation.
///
/// Start with `A2uiGenerator`, which holds the catalogs an agent supports and
/// hands out an `A2uiRequestProcessor` per renderer:
///
/// ```dart
/// final generator = A2uiGenerator(
///   catalogs: [CatalogConfig(MinimalCatalog())],
/// );
/// final processor = generator.createProcessor(rendererCapabilities);
/// final output = await callLlm(processor.promptSnippet, request);
/// final parts = processor.parseResponse(output);
/// ```
library;

export 'src/catalog_transformers/base.dart';
export 'src/catalog_transformers/pruning.dart';
export 'src/inference_format.dart';
export 'src/inference_formats/direct_json/constants.dart';
export 'src/inference_formats/direct_json/format.dart';
export 'src/inference_formats/direct_json/parser.dart';
export 'src/inference_formats/direct_json/payload_fixer.dart';
export 'src/inference_formats/direct_json/prompt_generator.dart';
export 'src/inference_formats/direct_json/streaming.dart';
export 'src/inference_formats/express/ast.dart';
export 'src/inference_formats/express/compiler.dart';
export 'src/inference_formats/express/constants.dart';
export 'src/inference_formats/express/decompiler.dart';
export 'src/inference_formats/express/format.dart';
export 'src/inference_formats/express/lexer.dart';
export 'src/inference_formats/express/parser.dart';
export 'src/inference_formats/express/prompt_generator.dart';
export 'src/inference_formats/express/statement_splitter.dart';
export 'src/inference_formats/express/syntax_parser.dart';
export 'src/parser/incremental_processor.dart';
export 'src/parser/parser.dart';
export 'src/parser/response_part.dart';
export 'src/parser/sentinel_tokenizer.dart';
export 'src/primitives/errors.dart';
export 'src/primitives/protocol_version.dart';
export 'src/processor/catalog_config.dart';
export 'src/processor/catalog_providers.dart';
export 'src/processor/generator.dart';
export 'src/processor/processor.dart';
export 'src/processor/renderer_capabilities.dart';
export 'src/prompt/generator.dart';
export 'src/utils/catalog_document.dart';
export 'src/utils/catalog_resolver.dart';
export 'src/utils/schema_utils.dart';
export 'src/validation/payload_validator.dart';
