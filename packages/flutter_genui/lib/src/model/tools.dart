// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';

import '../primitives/simple_items.dart';

/// Key used in schema definition to specify the component ID.
///
/// This key is used in prompts.
const surfaceIdKey = 'surfaceId';

/// Abstract base class for defining tools that an AI agent can invoke.
///
/// An [AiTool] represents a capability that the AI can use to interact with the
/// external environment or perform specific actions. For example, a tool could
/// allow the AI to save a file, query a database, or call an external API.
///
/// Concrete tool implementations must extend this class and provide:
/// - A unique [name] for the tool.
/// - A [description] of what the tool does, which helps the AI understand when
///   to use it.
/// - Optionally, a [parameters] schema defining the arguments the tool expects.
/// - An implementation of the [invoke] method to execute the tool's logic.
///
/// The generic argument determines the return type of [invoke], and must extend
/// a `Json` because that's what is required by the Gemini tool
/// calling API.
abstract class AiTool<T extends JsonMap> {
  /// Creates an instance of [AiTool].
  ///
  /// - [name]: A unique identifier for the tool. This name is used by the AI to
  ///   specify which tool to call.
  /// - [description]: A natural language description of the tool's purpose and
  ///   functionality. This helps the AI decide when and how to use the tool.
  /// - [parameters]: An optional [Schema] that defines the structure and types
  ///   of arguments the tool accepts. If the tool requires no arguments, this
  ///   can be omitted.
  const AiTool({
    required this.name,
    required this.description,
    this.parameters,
    this.prefix,
  });

  /// The unique name of the tool.
  ///
  /// For some tools, notably those from MCP servers, it is wise to namespace
  /// the tool with a [prefix].
  final String name;

  /// This is an optional name prefix that the tool will also be registered
  /// under.
  ///
  /// If the [prefix] is provided, the tool will be registered under both the
  /// [name] and the [fullName] strings. For example, a tool with the [name]
  /// "readFile" and a [prefix] of "file" would be registered under both
  /// "readFile" and "file.readFile".
  ///
  /// This is so that the AI can ask for the "readFile" tool, even if it was
  /// registered as "file.readFile", and it will still find the right tool.
  ///
  /// For MCP tools, prefixes are typically set to the name of the MCP server.
  final String? prefix;

  /// Returns the full name of the tool, including the [prefix] if it exists.
  ///
  /// If there is no prefix, this returns the [name] only.
  String get fullName => prefix == null ? name : '$prefix.$name';

  /// A description of what the tool does.
  final String description;

  /// An optional [Schema] defining the parameters the tool accepts.
  ///
  /// The tool is assumed to take no parameters if this is null,
  /// and the [invoke] function will be called with an empty Map.
  final Schema? parameters;

  /// Executes the tool's logic with the given [args].
  ///
  /// The [args] map contains the arguments provided by the AI, conforming to
  /// the [parameters] schema if one was defined.
  ///
  /// Returns a [Future] that completes with a map of results from the tool's
  /// execution. This result map will be sent back to the AI.
  Future<T> invoke(JsonMap args);
}

/// An [AiTool] that allows for dynamic invocation of a function.
///
/// This class is useful for creating tools where the invocation logic is
/// provided at runtime, for example, by a lambda or a closure.
class DynamicAiTool<T extends JsonMap> extends AiTool<T> {
  /// Creates a [DynamicAiTool].
  ///
  /// - [name]: The name of the tool.
  /// - [description]: A description of what the tool does.
  /// - [parameters]: An optional [Schema] defining the parameters the tool
  ///   accepts.
  /// - [invokeFunction]: The function to be called when the tool is invoked.
  ///   This function takes a map of arguments and returns a future map of
  ///   results.
  const DynamicAiTool({
    required super.name,
    required super.description,
    super.parameters,
    required this.invokeFunction,
    super.prefix,
  });

  /// The function that will be executed when this tool is invoked.
  ///
  /// It takes a map of arguments (matching the [parameters] schema, if
  /// provided) and returns a [Future] that resolves to a map of results.
  final Future<T> Function(JsonMap args) invokeFunction;

  @override
  Future<T> invoke(JsonMap args) {
    return invokeFunction(args);
  }
}
