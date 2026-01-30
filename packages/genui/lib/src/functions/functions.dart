// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../primitives/logging.dart';

/// A function that can be called from the UI definition.
typedef ClientFunction = Object? Function(List<Object?> args);

/// Registry of available client-side functions.
class FunctionRegistry {
  static final FunctionRegistry _instance = FunctionRegistry._init();

  factory FunctionRegistry() => _instance;

  FunctionRegistry._init() {
    registerStandardFunctions();
  }

  final Map<String, ClientFunction> _functions = {};

  /// Registers a function with the given [name].
  void register(String name, ClientFunction function) {
    _functions[name] = function;
  }

  /// Invokes a registered function with [name] and [args].
  Object? invoke(String name, List<Object?> args) {
    final ClientFunction? func = _functions[name];
    if (func == null) {
      genUiLogger.warning('Function not found: $name');
      return null;
    }
    try {
      return func(args);
    } catch (e, stack) {
      genUiLogger.severe('Error invoking function $name', e, stack);
      return null;
    }
  }

  /// Registers all standard A2UI functions.
  void registerStandardFunctions() {
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
  }

  // --- Implementations ---

  Object? _required(List<Object?> args) {
    if (args.isEmpty) return false;
    final Object? value = args[0];
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  Object? _regex(List<Object?> args) {
    if (args.length < 2) return false;
    final Object? value = args[0];
    final Object? pattern = args[1];
    if (value is! String || pattern is! String) return false;
    try {
      return RegExp(pattern).hasMatch(value);
    } catch (e) {
      genUiLogger.warning('Invalid regex pattern: $pattern');
      return false;
    }
  }

  Object? _length(List<Object?> args) {
    if (args.length < 2) return false;
    final Object? value = args[0];
    final Object? constraints = args[1];
    if (constraints is! Map) return false;

    int? len;
    if (value is String) {
      len = value.length;
    } else if (value is List) {
      len = value.length;
    } else {
      return false;
    }

    if (constraints.containsKey('min')) {
      final Object? min = constraints['min'];
      if (min is num && len < min) return false;
    }
    if (constraints.containsKey('max')) {
      final Object? max = constraints['max'];
      if (max is num && len > max) return false;
    }
    return true;
  }

  Object? _numeric(List<Object?> args) {
    if (args.length < 2) return false;
    final Object? value = args[0];
    final Object? constraints = args[1];
    if (constraints is! Map) return false;

    if (value is! num) return false;

    if (constraints.containsKey('min')) {
      final Object? min = constraints['min'];
      if (min is num && value < min) return false;
    }
    if (constraints.containsKey('max')) {
      final Object? max = constraints['max'];
      if (max is num && value > max) return false;
    }
    return true;
  }

  Object? _email(List<Object?> args) {
    if (args.isEmpty) return false;
    final Object? value = args[0];
    if (value is! String) return false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(value);
  }

  Object? _formatString(List<Object?> args) {
    if (args.isEmpty) return '';
    return args[0]?.toString() ?? '';
  }

  Object? _openUrl(List<Object?> args) {
    if (args.isEmpty) return false;
    final Object? urlStr = args[0];
    if (urlStr is! String) return false;
    final Uri? uri = Uri.tryParse(urlStr);
    if (uri != null) {
      launchUrl(uri).catchError((Object? e) {
        genUiLogger.warning('Failed to launch URL: $urlStr', e);
        return false;
      });
      return true;
    }
    return false;
  }

  Object? _formatNumber(List<Object?> args) {
    if (args.isEmpty) return '';
    final Object? number = args[0];
    if (number is! num) return number?.toString();

    int? decimalPlaces;
    if (args.length > 1 && args[1] is num) {
      decimalPlaces = (args[1] as num).toInt();
    }

    var useGrouping = true;
    if (args.length > 2 && args[2] is bool) {
      useGrouping = args[2] as bool;
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

  Object? _formatCurrency(List<Object?> args) {
    if (args.length < 2) return '';
    final Object? amount = args[0];
    final Object? currencyCode = args[1];
    if (amount is! num || currencyCode is! String) return amount?.toString();

    final formatter = NumberFormat.simpleCurrency(name: currencyCode);
    return formatter.format(amount);
  }

  Object? _formatDate(List<Object?> args) {
    if (args.length < 2) return '';
    final Object? dateVal = args[0];
    final Object? pattern = args[1];

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

  Object? _pluralize(List<Object?> args) {
    if (args.isEmpty) return '';
    final Object? count = args[0];
    if (count is! num) return '';

    if (args.length == 2 && args[1] is Map) {
      final options = args[1] as Map;
      if (count == 0 && options.containsKey('zero')) return options['zero'];
      if (count == 1 && options.containsKey('one')) return options['one'];
      return options['other'] ?? '';
    }

    return '';
  }
}
