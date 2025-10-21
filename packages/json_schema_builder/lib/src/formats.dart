// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_validator/email_validator.dart';
import 'package:intl/intl.dart';

/// A function that validates a string against a format.
///
/// Returns `true` if the string is valid, and `false` otherwise.
typedef FormatValidator = bool Function(String);

/// A map of format names to their validation functions.
///
/// This is used to validate string formats like 'date-time', 'email', etc.
final Map<String, FormatValidator> formatValidators = {
  'date-time': (value) {
    try {
      DateTime.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  },
  'date': (value) {
    try {
      DateFormat('yyyy-MM-dd').parseStrict(value);
      return true;
    } catch (e) {
      return false;
    }
  },
  'time': (value) {
    try {
      DateFormat('HH:mm:ss').parseStrict(value);
      return true;
    } catch (e) {
      return false;
    }
  },
  'email': EmailValidator.validate,
  'ipv4': (value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final n = int.tryParse(part);
      return n != null && n >= 0 && n <= 255;
    });
  },
  'ipv6': (value) {
    try {
      Uri.parseIPv6Address(value);
      return true;
    } catch (e) {
      return false;
    }
  },
};
