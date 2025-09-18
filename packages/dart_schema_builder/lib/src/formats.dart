// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';

typedef FormatValidator = bool Function(String);

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
  'email': (value) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(value);
  },
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
