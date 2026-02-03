# genai_primitives

This package provides a set of technology-agnostic primitive types and data structures for building Generative AI applications in Dart.

It includes core definitions such as `ChatMessage`, `Parts`, `ToolDefinition` and other foundational classes that are used across the `genai` ecosystem to ensure consistency and interoperability between different AI providers.

## Core Types

* [`Part`](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/parts/model.dart): Base type for message parts. Extend this to define custom part types.

* [`Parts`](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/parts/parts.dart): A collection of `Part` instances with utility methods.

* [`StandardPart`](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/parts/standard_part.dart): Sealed class extending `Part` with a fixed set of implementations. Used by `ChatMessage` for cross-provider compatibility.

* [`ChatMessage`](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/chat_message.dart): Represents a chat message compatible with most GenAI providers.

* [`ToolDefinition`](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/tool_definition.dart): Defines a tool that can be invoked by an LLM.

## Aliasing

If you need to resolve name conflicts with other packages, alias the package as `genai`:

```dart
import 'package:genai_primitives/genai_primitives.dart' as genai;
```
