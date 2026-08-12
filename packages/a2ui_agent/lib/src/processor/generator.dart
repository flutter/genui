// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a2ui_core/a2ui_core.dart';

import '../inference_format.dart';
import '../inference_formats/direct_json/format.dart';
import '../primitives/protocol_version.dart';
import '../prompt/generator.dart';
import '../utils/catalog_resolver.dart';
import 'catalog_config.dart';
import 'processor.dart';
import 'renderer_capabilities.dart';

/// The agent-level entry point of the A2UI agent SDK.
///
/// A generator is long lived: it holds every catalog the agent supports and
/// the examples shared across sessions, and hands out an
/// [A2uiRequestProcessor] per renderer capability signature. Build one at
/// startup and call [createProcessor] in the request handler.
class A2uiGenerator {
  /// Every catalog this agent supports, in preference order.
  final List<CatalogConfig> catalogs;

  /// Few-shot example turns shared by every session.
  final PromptExamples? examples;

  /// The format used when [createProcessor] is not given one.
  final InferenceFormatFactory inferenceFormatFactory;

  /// The protocol version this agent speaks.
  final ProtocolVersion protocolVersion;

  /// Whether catalogs a renderer sends inline are accepted.
  final bool acceptsInlineCatalogs;

  A2uiGenerator({
    required List<CatalogConfig> catalogs,
    this.examples,
    InferenceFormatFactory? inferenceFormatFactory,
    this.protocolVersion = ProtocolVersion.current,
    this.acceptsInlineCatalogs = false,
  }) : catalogs = List<CatalogConfig>.unmodifiable(catalogs),
       inferenceFormatFactory =
           inferenceFormatFactory ?? const DirectJsonFormatFactory();

  /// Creates a processor bound to what [rendererCapabilities] can render.
  ///
  /// The catalogs are negotiated first, then the configured examples are
  /// validated against the ones that survived: an example is part of the
  /// prompt, so an example that does not conform to the active catalogs is a
  /// bug that would otherwise surface as bad model output.
  ///
  /// Throws [A2uiCapabilityError](../primitives/errors.dart) when the agent
  /// and the renderer share no catalog, and [A2uiValidationError] when an
  /// example does not conform to the negotiated catalogs.
  A2uiRequestProcessor createProcessor(
    A2uiRendererCapabilities rendererCapabilities, {
    InferenceFormatFactory? inferenceFormatFactory,
    bool? acceptsInlineCatalogs,
  }) {
    final List<Catalog<ComponentApi>> active = resolveCatalogs(
      catalogs,
      rendererCapabilities,
      acceptsInlineCatalogs:
          acceptsInlineCatalogs ?? this.acceptsInlineCatalogs,
    );

    final processor = A2uiRequestProcessor(
      catalogs: active,
      examples: examples,
      formatFactory: inferenceFormatFactory ?? this.inferenceFormatFactory,
      protocolVersion: protocolVersion,
    );
    processor.validateExamples();
    return processor;
  }

  /// The capabilities an agent-side renderer would report for these catalogs.
  ///
  /// Useful for tests and for local agents that render their own output.
  A2uiRendererCapabilities get supportedCapabilities =>
      A2uiRendererCapabilities(
        supportedCatalogIds: [
          for (final CatalogConfig config in catalogs) config.id,
        ],
        protocolVersion: protocolVersion,
      );
}
