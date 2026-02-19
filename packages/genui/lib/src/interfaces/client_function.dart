// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:json_schema_builder/json_schema_builder.dart';

import '../model/data_model.dart';
import '../primitives/simple_items.dart';

/// A function that can be invoked by the GenUI expression system.
///
/// Functions are reactive, returning a [Stream] of values.
/// This allows functions to push updates to the UI (e.g. a clock or network
/// status).
abstract interface class ClientFunction {
  /// The name of the function as used in expressions (e.g. 'stringFormat').
  String get name;

  /// The schema for the arguments this function accepts.
  /// Used for validation and tool definition generation for the LLM.
  Schema get argumentSchema;

  /// Invokes the function with the given [args].
  ///
  /// Returns a stream of values.
  ///
  /// **Reactivity:**
  /// - **Argument Changes:** If the input [args] change (e.g. because they were
  ///   bound to a changing data path), the `ExpressionParser` will
  ///   **re-invoke** this function with the new arguments. The previous stream
  ///   will be cancelled, and the new stream subscribed to. Therefore, a single
  ///   stream instance does *not* need to handle argument changes.
  /// - **Internal Changes:** The stream *should* emit new values if the
  ///   function's internal sources change (e.g. a clock tick, a network status
  ///   change, or a subscription to a data path looked up via [context]).
  ///
  /// The [context] is provided to allow the function to resolve other paths
  /// or interact with the `DataModel` if necessary (e.g. `subscribeToValue`).
  Stream<Object?> execute(JsonMap args, DataContext context);
}

/// A base class for synchronous client functions.
///
/// Implementers should override [executeSync] to provide the synchronous logic.
abstract class SynchronousClientFunction implements ClientFunction {
  const SynchronousClientFunction();

  @override
  Stream<Object?> execute(JsonMap args, DataContext context) {
    try {
      return Stream.value(executeSync(args, context));
    } catch (e, stack) {
      return Stream.error(e, stack);
    }
  }

  /// Executes the function synchronously.
  Object? executeSync(JsonMap args, DataContext context);
}
