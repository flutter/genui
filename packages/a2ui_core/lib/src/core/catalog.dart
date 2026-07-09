// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_schema_builder/json_schema_builder.dart';
import '../primitives/cancellation.dart';
import '../primitives/errors.dart';
import '../primitives/identifiers.dart';
import '../primitives/reactivity.dart';
import 'contexts.dart';

/// A definition of a UI component's API.
abstract class ComponentApi {
  String get name;
  Schema get schema;
}

/// The type of value a function returns.
enum A2uiReturnType {
  string,
  number,
  boolean,
  array,
  object,
  any,
  void_;

  /// The JSON value used in the A2UI protocol.
  String get jsonValue => this == void_ ? 'void' : name;

  /// Parses from the JSON string representation.
  static A2uiReturnType fromJson(String value) {
    if (value == 'void') return void_;
    return values.byName(value);
  }
}

/// Where a catalog function may be invoked from.
enum A2uiCallableFrom {
  /// Only callable locally on the client (e.g. in data bindings and
  /// component actions).
  clientOnly,

  /// Only callable by the server via `callFunction` messages.
  remoteOnly,

  /// Callable both locally and via `callFunction` messages.
  clientOrRemote;

  /// The JSON value used in the A2UI protocol.
  String get jsonValue => name;

  /// Parses from the JSON string representation.
  static A2uiCallableFrom fromJson(String value) => values.byName(value);

  /// Whether the function may be invoked locally on the client.
  bool get isClientCallable => this != remoteOnly;

  /// Whether the function may be invoked by the server via `callFunction`.
  bool get isRemoteCallable => this != clientOnly;
}

/// A definition of a UI function's API.
abstract class FunctionApi {
  String get name;
  A2uiReturnType get returnType;
  Schema get argumentSchema;

  /// Where this function may be invoked from. Defaults to
  /// [A2uiCallableFrom.clientOnly].
  A2uiCallableFrom get callableFrom => A2uiCallableFrom.clientOnly;
}

/// A function implementation that can be registered with a catalog.
abstract class FunctionImplementation extends FunctionApi {
  /// Executes the function. Can return a static value or a [ReadonlySignal].
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]);
}

/// A collection of available components and functions.
class Catalog<T extends ComponentApi> {
  final String id;
  final Map<String, T> components;
  final Map<String, FunctionImplementation> functions;
  final Schema? surfacePropertiesSchema;

  /// Optional Markdown design guidelines and component usage rules embedded
  /// directly in the catalog.
  final String? instructions;

  Catalog({
    required this.id,
    required List<T> components,
    List<FunctionImplementation> functions = const [],
    this.surfacePropertiesSchema,
    this.instructions,
  }) : components = {for (var c in components) c.name: c},
       functions = {for (var f in functions) f.name: f} {
    for (final String name in [
      ...this.components.keys,
      ...this.functions.keys,
    ]) {
      if (!isValidA2uiIdentifier(name)) {
        throw A2uiValidationError(
          "Catalog entity name '$name' does not conform to UAX #31 "
          'identifier rules.',
        );
      }
    }
  }
}
