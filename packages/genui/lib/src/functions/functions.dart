// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../primitives/logging.dart';

/// A function that can be called from the UI definition.
typedef ClientFunction = Object? Function(Map<String, Object?> args);

/// Registry of available client-side functions.
class FunctionRegistry {
  static final FunctionRegistry _instance = FunctionRegistry._init();

  factory FunctionRegistry() => _instance;

  FunctionRegistry._init() {
    registerBasicFunctions();
  }

  final Map<String, ClientFunction> _functions = {};

  /// Registers a function with the given [name].
  void register(String name, ClientFunction function) {
    _functions[name] = function;
  }

  /// Invokes a registered function with [name] and [args].
  Object? invoke(String name, Map<String, Object?> args) {
    final ClientFunction? func = _functions[name];
    if (func == null) {
      genUiLogger.warning('Function not found: $name');
      return null;
    }
    try {
      return func(args);
    } catch (exception, stackTrace) {
      throw FunctionInvocationException(name, exception, stackTrace);
    }
  }

  /// Registers all basic A2UI functions.
  void registerBasicFunctions() {
    register('required', _required);
    register('regex', _regex);
    register('length', _length);
    register('numeric', _numeric);
    register('email', _email);
    register('formatString', _formatString);
    register('openUrl', _openUrl);
    register('formatNumber', _formatNumber);
    register('formatCurrency', _formatCurrency);
    register('formatDate', _formatDate);
    register('pluralize', _pluralize);
    register('and', _and);
    register('or', _or);
    register('not', _not);
  }

  // --- Implementations ---

  Object? _and(Map<String, Object?> args) {
    if (!args.containsKey('values')) return false;
    final Object? values = args['values'];
    if (values is! List) return false;
    // We assume the caller (parser) has evaluated the list items if they were
    // expressions, but if the list contains plain boolean values or
    // truthy/falsy values, we check them.
    for (final Object? element in values) {
      if (!_isTruthy(element)) return false;
    }
    return true;
  }

  Object? _or(Map<String, Object?> args) {
    if (!args.containsKey('values')) return false;
    final Object? values = args['values'];
    if (values is! List) return false;
    for (final Object? element in values) {
      if (_isTruthy(element)) return true;
    }
    return false;
  }

  Object? _not(Map<String, Object?> args) {
    if (!args.containsKey('value')) return false;
    return !_isTruthy(args['value']);
  }

  bool _isTruthy(Object? value) {
    if (value is bool) return value;
    if (value == null) return false;
    // You might want to define other truthy rules here
    return true;
  }

  Object? _required(Map<String, Object?> args) {
    if (!args.containsKey('value')) return false;
    final Object? value = args['value'];
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  Object? _regex(Map<String, Object?> args) {
    final Object? value = args['value'];
    final Object? pattern = args['pattern'];
    if (value is! String || pattern is! String) return false;
    try {
      return RegExp(pattern).hasMatch(value);
    } on FormatException catch (exception, stackTrace) {
      throw FunctionInvocationException(
        'regex',
        'Invalid regex pattern: $pattern. $exception',
        stackTrace,
      );
    }
  }

  Object? _length(Map<String, Object?> args) {
    final Object? value = args['value'];
    if (value == null) return false;

    int? len;
    if (value is String) {
      len = value.length;
    } else if (value is List) {
      len = value.length;
    } else {
      return false;
    }

    if (args.containsKey('min')) {
      final Object? min = args['min'];
      if (min is num && len < min) return false;
    }
    if (args.containsKey('max')) {
      final Object? max = args['max'];
      if (max is num && len > max) return false;
    }
    return true;
  }

  Object? _numeric(Map<String, Object?> args) {
    final Object? value = args['value'];
    if (value is! num) return false;

    if (args.containsKey('min')) {
      final Object? min = args['min'];
      if (min is num && value < min) return false;
    }
    if (args.containsKey('max')) {
      final Object? max = args['max'];
      if (max is num && value > max) return false;
    }
    return true;
  }

  Object? _email(Map<String, Object?> args) {
    final Object? value = args['value'];
    if (value is! String) return false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(value);
  }

  Object? _formatString(Map<String, Object?> args) {
    return args['value']?.toString() ?? '';
  }

  Object? _openUrl(Map<String, Object?> args) async {
    final Object? urlStr = args['url'];
    if (urlStr is! String) return false;
    final Uri? uri = Uri.tryParse(urlStr);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    }
    return false;
  }

  Object? _formatNumber(Map<String, Object?> args) {
    final Object? number = args['value'];
    if (number is! num) return number?.toString() ?? '';

    int? decimalPlaces;
    if (args['decimalPlaces'] is num) {
      decimalPlaces = (args['decimalPlaces'] as num).toInt();
    }

    var useGrouping = true;
    if (args['useGrouping'] is bool) {
      useGrouping = args['useGrouping'] as bool;
    }

    final formatter = NumberFormat.decimalPattern(); // Default locale
    if (!useGrouping) {
      formatter.turnOffGrouping();
    }
    if (decimalPlaces != null) {
      formatter.minimumFractionDigits = decimalPlaces;
      formatter.maximumFractionDigits = decimalPlaces;
    }

    return formatter.format(number);
  }

  Object? _formatCurrency(Map<String, Object?> args) {
    final Object? amount = args['value'];
    final Object? currencyCode = args['currencyCode'];
    if (amount is! num || currencyCode is! String) {
      return amount?.toString() ?? '';
    }

    final formatter = NumberFormat.simpleCurrency(name: currencyCode);
    return formatter.format(amount);
  }

  Object? _formatDate(Map<String, Object?> args) {
    final Object? dateVal = args['value'];
    final Object? pattern = args['pattern'];

    DateTime? date;
    if (dateVal is String) {
      date = DateTime.tryParse(dateVal);
    } else if (dateVal is int) {
      date = DateTime.fromMillisecondsSinceEpoch(dateVal);
    }

    if (date == null || pattern is! String) return dateVal?.toString();

    try {
      return DateFormat(pattern).format(date);
    } catch (e) {
      return date.toString();
    }
  }

  Object? _pluralize(Map<String, Object?> args) {
    final Object? count = args['count'];
    if (count is! num) return '';

    if (count == 0 && args.containsKey('zero')) return args['zero'];
    if (count == 1 && args.containsKey('one')) return args['one'];
    return args['other'] ?? '';
  }
}

/// Exception thrown when a function invocation fails.
class FunctionInvocationException implements Exception {
  /// Creates a [FunctionInvocationException].
  FunctionInvocationException(this.functionName, this.cause, [this.stack]);

  /// The name of the function that failed.
  final String functionName;

  /// The underlying cause of the failure.
  final Object cause;

  /// The stack trace.
  final StackTrace? stack;

  @override
  String toString() => 'Error invoking function "$functionName": $cause';
}
