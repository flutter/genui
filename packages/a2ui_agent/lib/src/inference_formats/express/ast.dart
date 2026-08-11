// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An expression in an A2UI Express statement.
sealed class ExpressExpression {
  /// The 1-based line the expression starts on.
  final int line;

  const ExpressExpression(this.line);
}

/// A primitive literal: string, number, boolean or null.
final class LiteralExpression extends ExpressExpression {
  /// The decoded literal value.
  final Object? value;

  /// Whether the literal was written as a raw string (`r"..."`).
  ///
  /// Raw strings survive a decompile round trip unescaped, which matters for
  /// validation patterns full of backslashes.
  final bool isRawString;

  const LiteralExpression(super.line, this.value, {this.isRawString = false});
}

/// A data binding path, written `$/absolute` or `$relative`.
final class PathExpression extends ExpressExpression {
  /// The path with the `$` prefix removed.
  final String path;

  const PathExpression(super.line, this.path);
}

/// A reference to a variable defined elsewhere in the block.
final class VariableExpression extends ExpressExpression {
  /// The variable name.
  final String name;

  const VariableExpression(super.line, this.name);
}

/// The `_` placeholder that skips an optional positional argument.
final class SkippedExpression extends ExpressExpression {
  const SkippedExpression(super.line);
}

/// A list of expressions, written `[a, b]`.
final class ArrayExpression extends ExpressExpression {
  /// The list elements, in source order.
  final List<ExpressExpression> items;

  const ArrayExpression(super.line, this.items);
}

/// A key-value structure, written `{key: value}`.
final class MapExpression extends ExpressExpression {
  /// The entries, in source order.
  final Map<String, ExpressExpression> entries;

  const MapExpression(super.line, this.entries);
}

/// A call to a component constructor, catalog function or reserved helper.
final class CallExpression extends ExpressExpression {
  /// The name being called.
  final String name;

  /// The arguments, positional and named, in source order.
  final List<ExpressArgument> arguments;

  const CallExpression(super.line, this.name, this.arguments);

  /// The positional arguments, in order.
  List<ExpressExpression> get positional => [
    for (final ExpressArgument argument in arguments)
      if (argument.name == null) argument.value,
  ];

  /// The named arguments, keyed by parameter name.
  Map<String, ExpressExpression> get named => {
    for (final ExpressArgument argument in arguments)
      if (argument.name != null) argument.name!: argument.value,
  };
}

/// A validation check, written `?required` or `?regex(pattern, message)`.
final class CheckExpression extends ExpressExpression {
  /// The name of the check function in the catalog.
  final String name;

  /// The check arguments, in source order.
  final List<ExpressExpression> arguments;

  const CheckExpression(super.line, this.name, this.arguments);
}

/// One argument of a [CallExpression].
class ExpressArgument {
  /// The parameter name for `param=value` arguments, or null when positional.
  final String? name;

  /// The argument value.
  final ExpressExpression value;

  const ExpressArgument({this.name, required this.value});
}

/// A statement in an A2UI Express block.
sealed class ExpressStatement {
  /// The 1-based line the statement starts on.
  final int line;

  const ExpressStatement(this.line);
}

/// Assigns a component or value to a variable, e.g. `root = Card(body)`.
final class VariableAssignment extends ExpressStatement {
  /// The variable being defined. Doubles as the compiled component id.
  final String name;

  /// The assigned expression.
  final ExpressExpression value;

  const VariableAssignment(super.line, this.name, this.value);
}

/// Populates a data model path, e.g. `$/title = "Hello"`.
final class DataAssignment extends ExpressStatement {
  /// The target path, with the `$` prefix removed.
  final String path;

  /// The assigned expression.
  final ExpressExpression value;

  const DataAssignment(super.line, this.path, this.value);
}

/// A standalone call, e.g. `surface("main")` or `deleteSurface("main")`.
final class CallStatement extends ExpressStatement {
  /// The call being made.
  final CallExpression call;

  const CallStatement(super.line, this.call);
}
