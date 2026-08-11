# A2UI Agent SDK

The agent side of [A2UI](https://a2ui.org) for Dart:
when agent and renderer are in different processes, this SDK is
what is needed on agent side.

It covers catalog management, capability negotiation, prompt engineering,
response parsing, payload validation and transport packaging, so an agent can
generate rich UI that provably conforms to what its client can render.

Built on [`package:a2ui_core`](../a2ui_core), which supplies the protocol
models this SDK negotiates, prompts with and validates against.

## Getting started

```dart
import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';

// 1. At startup: register the catalogs this agent supports.
final generator = A2uiGenerator(
  catalogs: [
    CatalogConfig(
      MinimalCatalog(),
      transformers: [
        ComponentPruningTransformer(['Column', 'Text', 'Button']),
      ],
    ),
  ],
  examples: {'A greeting card': greetingMessages},
);

// 2. Per request: negotiate against what the renderer can render.
final processor = generator.createProcessor(
  A2uiRendererCapabilities.fromJson(request.a2uiClientCapabilities),
);

// 3. Prompt the model, prepending your own role and workflow instructions.
final output = await callLlm('$roleInstructions\n${processor.promptSnippet}');

// 4. Parse and validate.
for (final part in processor.parseResponse(output)) {
  switch (part) {
    case TextPart(:final text):
      sendText(text);
    case A2uiPart(:final a2ui):
      sendToRenderer(a2ui); // 5. Deliver.
  }
}
```

Run the full walkthrough with
`dart run example/a2ui_agent_example.dart`.

## Architecture

The SDK separates single-responsibility primitives from a high-level facade, so
that an agent can adopt the whole pipeline or reach past it for one piece.

| Layer                | Types                                                                             |
| -------------------- | --------------------------------------------------------------------------------- |
| Application facade   | `A2uiGenerator`, `A2uiRequestProcessor`, `CatalogConfig`, catalog providers       |
| Catalog transformers | `CatalogTransformer`, `ComponentPruningTransformer`, `FunctionPruningTransformer` |
| Inference formats    | `InferenceFormat`, `InferenceFormatFactory`, `DirectJsonFormat`, `ExpressFormat`  |
| Prompt generation    | `PromptGenerator` and the per-format generators                                   |
| Parsing              | `Parser`, `RawResponsePart`, `TextPart`, `RawA2uiPart`, `A2uiPart`                |
| Validation           | `A2uiPayloadValidator`                                                            |
| Negotiation          | `resolveCatalogs`, `A2uiRendererCapabilities`                                     |

### Catalogs

A catalog is a `a2ui_core` `Catalog`: either written in Dart, or loaded from a
catalog document with `FileSystemCatalogProvider`, `InMemoryCatalogProvider` or
`BundledCatalogProvider`. `CatalogConfig` pairs one with the transformers that
trim it; the pristine catalog is never mutated.

`resolveCatalogs` matches the registered catalogs against the renderer's
`a2uiClientCapabilities` and returns the transformed catalogs active for the
session. A catalog the renderer cannot render never reaches the prompt, so the
model cannot name a component the client would reject. If nothing matches, the
call throws rather than letting a doomed inference run.

### Inference formats

A format pairs a prompt generator with a parser.

**Direct JSON** (the default) has the model emit A2UI wire JSON inside
`<a2ui-json>` tags:

```
<a2ui-json>
[{"version": "v0.9", "updateComponents": {"surfaceId": "s", "components": [
  {"id": "root", "component": "Text", "text": "Hello"}
]}}]
</a2ui-json>
```

**Express** trades that verbosity for a positional DSL inside
`<a2ui-express>` tags, which cuts output tokens substantially — the reason the
format exists:

```
<a2ui-express>
surface("s")
root = Column([title, cta])
title = Text($/heading, "h1")
cta = Button(Text("Continue"), Event("continue"))
</a2ui-express>
```

Express is catalog-agnostic: positional arguments are mapped onto property
names through the catalog signature, and the same function renders the
signature shown to the model, so the syntax it is taught is exactly the syntax
its output is parsed against. `ExpressDecompiler` converts payloads back to
Express, which is how few-shot examples authored as A2UI JSON are shown to the
model in the compact syntax.

Select a format per agent or per request:

```dart
generator.createProcessor(
  capabilities,
  inferenceFormatFactory: const ExpressFormatFactory(),
);
```

### Streaming

Both formats parse incrementally. `parseChunk` returns only what became usable
since the previous call, and `parseStream` wraps that as a `Stream`:

```dart
await for (final part in processor.parseStream(modelChunks)) {
  // TextPart and A2uiPart, in the order the model produced them.
}
```

Direct JSON emits a component as soon as it is renderable and re-emits it only
when its content actually changed, so a string grows on screen as it arrives.
Truncated values are healed only for property keys where a prefix is a
legitimate value — never for component references, enums or pattern-constrained
strings, where a prefix would be wrong rather than merely incomplete. Express
compiles statement by statement as each line completes.

A payload the model never finished is salvaged as far as it parses, rather than
discarded.

### Validation

`A2uiPayloadValidator` checks compiled payloads against the negotiated
catalogs: envelope version, catalog identity, component existence, required and
unknown properties, duplicate ids, JSON Pointer syntax, and — opt in —
dangling child references and reference cycles. Parsing runs it automatically,
so `parseResponse` either returns a conforming payload or throws.

Prompt examples are validated too, when the processor is created: an example
that names a component the negotiated catalogs lack would teach the model to
emit exactly what the renderer will reject.

## Relationship to the specification

This package implements the
[A2UI agent SDK blueprint](https://github.com/a2ui-project/a2ui/blob/main/blueprints/modules/a2ui_agent.blueprint.md).
Where Dart differs from the reference Python SDK:

- The blueprint's `AgentToRendererMessage` is `a2ui_core`'s `A2uiMessage`; the
  name is available as a typedef.
- `package:a2ui_core` models the `v0.9` envelopes, so payloads compile to
  `createSurface`, `updateComponents`, `updateDataModel` and `deleteSurface`.
  `ProtocolVersion` names the other versions so that a catalog declaring one is
  reported rather than silently mis-parsed.
- Validation lives here rather than in the core package, which does not yet
  ship an `A2uiValidator`.
- Express targets `v0.9`, so a standalone function call — a `callFunction` RPC
  in `v1.0` — is reported as unsupported instead of being dropped.
- `BundledCatalogProvider` serves the minimal catalog bundled with
  `a2ui_core` for `v0.9`.
- Catalog transformers are pure functions over `Catalog`, and generic over the
  component type, so pruning a typed catalog returns a catalog of the same
  type.

`FileSystemCatalogProvider` and `CatalogConfig.fromPath` read from disk and so
require a native platform.
