# genai_primitives

This package provides a set of technology-agnostic primitive types and data structures for building Generative AI applications in Dart.

It includes core definitions such as `ChatMessage`, `Parts`, `ToolDefinition` and other foundational classes that are used across the `genai` ecosystem to ensure consistency and interoperability between different AI providers.

## Core Types

* [`Part`](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/parts/model.dart): Flexible base type for message parts. To define custom parts of message derive from this type.

* [`Parts`](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/parts/parts.dart): collection of instances of `Part` with helpers.

* [`StandardPart` (extends `Part`)](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/parts/standard_part.dart): sealed class with fixed set of implementations, utilized by `ChatMessage`. 
To reach consistency with other packages and LLM providers, use StandardPart.

* [ChatMessage](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/chat_message.dart): class that represent chat message compatible with most gen AI model and framework providers. 

* [ToolDefinition](https://github.com/flutter/genui/blob/main/packages/genai_primitives/lib/src/tool_definition.dart): definition of a tool that can be called by LLM.

## Aliasing

If you need to resolve name conflicts with other packages, alias the package as `genai`:

```dart
import 'package:genai_primitives/genai_primitives.dart' as genai;
```
